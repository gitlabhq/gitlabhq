# frozen_string_literal: true

module SentNotificationsShared # rubocop:disable Gitlab/BoundedContexts -- Temporary module to partition table
  extend ActiveSupport::Concern

  INVALID_NOTEABLE = Class.new(StandardError)
  REPLY_KEY_BYTE_SIZE = 16
  INTEGER_CONVERT_BASE = 36
  BASE36_REGEX = /[0-9a-z]/
  # Email reply key is in the form: <base36-partition-id>-<base36-reply-key>
  PARTITIONED_REPLY_KEY_REGEX = /(?<partition>#{BASE36_REGEX}{1,4})-(?<reply_key>#{BASE36_REGEX}{25})/
  LEGACY_REPLY_KEY_REGEX = /(?<legacy_key>[a-f\d]{32})/
  FULL_REPLY_KEY_REGEX = /(?:(#{LEGACY_REPLY_KEY_REGEX})|(#{PARTITIONED_REPLY_KEY_REGEX}))/

  included do
    include EachBatch

    belongs_to :project
    belongs_to :noteable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations -- Legacy definition
    belongs_to :recipient, class_name: "User"
    belongs_to :issue_email_participant
    belongs_to :namespace

    validates :recipient, :namespace_id, presence: true
    validates :reply_key, presence: true, uniqueness: true
    validates :noteable_id, presence: true, unless: :for_commit?
    validates :commit_id, :project, presence: true, if: :for_commit?
    validates :in_reply_to_discussion_id, format: { with: /\A\h{40}\z/, allow_nil: true }
    validate :note_valid

    before_validation :ensure_sharding_key
  end

  class_methods do
    def reply_key
      # Adding leading 0 to make the key size stable. 25 is the max we can get with 16 bytes
      SecureRandom.random_number(2**(REPLY_KEY_BYTE_SIZE * 8)).to_s(INTEGER_CONVERT_BASE).rjust(25, '0')
    end

    def for(reply_key)
      matches = FULL_REPLY_KEY_REGEX.match(reply_key)
      return unless matches

      if matches[:reply_key]
        ::PartitionedSentNotification.find_by(partition: matches[:partition], reply_key: matches[:reply_key])
      else
        klass = Feature.enabled?(:insert_into_p_sent_notifications, :instance) ? ::PartitionedSentNotification : self

        klass.find_by(reply_key: matches[:legacy_key])
      end
    end

    def record(noteable, recipient_id, attrs = {})
      noteable_id = nil
      commit_id = nil
      if noteable.is_a?(Commit)
        commit_id = noteable.id
      else
        noteable_id = noteable.id
      end

      attrs.reverse_merge!(
        project: noteable.project,
        recipient_id: recipient_id,
        reply_key: reply_key,

        noteable_type: noteable.class.name,
        noteable_id: noteable_id,
        commit_id: commit_id
      )

      if Feature.enabled?(:insert_into_p_sent_notifications, :instance)
        # Non-sticky write is used as `.record` is only used in ActionMailer
        # where there are no queries to SentNotification.
        new_record = ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
          ::PartitionedSentNotification.create(attrs)
        end

        return new_record
      end

      legacy_record = ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
        create(attrs)
      end

      return legacy_record unless legacy_record.persisted?

      # This is temporary until we only use the new partitioned table. As a first step will continue to write
      # only to the original table and let the trigger write to the parttioned table. When reads look good, we
      # can start writing directly to the new table
      ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).use_primary(write_fallback: false) do
        ::PartitionedSentNotification.find_by(id: legacy_record.id)
      end
    end

    def record_note(note, recipient_id, attrs = {})
      attrs[:in_reply_to_discussion_id] = note.discussion_id if note.part_of_discussion? || note.can_be_discussion_note?

      record(note.noteable, recipient_id, attrs)
    end
  end

  def unsubscribable?
    !(for_commit? || for_snippet?)
  end

  def for_commit?
    noteable_type == "Commit"
  end

  def for_snippet?
    noteable_type.end_with?('Snippet')
  end

  def noteable
    if for_commit?
      begin
        project.commit(commit_id)
      rescue StandardError
        nil
      end
    else
      super
    end
  end

  def to_param
    partitioned_reply_key
  end

  def create_reply(message, external_author = nil, dryrun: false)
    klass = dryrun ? Notes::BuildService : Notes::CreateService
    params = reply_params.merge(
      note: message
    )

    params[:external_author] = external_author if external_author.present?

    klass.new(project,
      recipient,
      params
    ).execute
  end

  def ==(other)
    super ||
      (other.is_a?(::SentNotificationsShared) && id.present? && other['id'] == self['id'])
  end

  private

  def ensure_sharding_key
    self.namespace_id = namespace_id_from_noteable
  end

  def namespace_id_from_noteable
    case noteable
    when DesignManagement::Design, Issue
      noteable.namespace_id
    when MergeRequest, ProjectSnippet
      noteable.project.project_namespace_id
    when Commit
      project&.project_namespace_id
    when WikiPage::Meta
      noteable.namespace_id || noteable.project.project_namespace_id
    else
      # Raising an error here to make sure that the correct sharding key is set if support
      # for a new `noteable_type` is added.
      raise(
        INVALID_NOTEABLE,
        format(_("%{noteable_type} is not supported"), noteable_type: noteable_type)
      )
    end
  end

  def reply_params
    {
      noteable_type: noteable_type,
      noteable_id: noteable_id,
      commit_id: commit_id,
      in_reply_to_discussion_id: in_reply_to_discussion_id
    }
  end

  def note_valid
    note = create_reply('Test', dryrun: true)
    return if note.valid?

    errors.add(
      :base, format(_("Note parameters are invalid: %{errors}"), errors: note.errors.full_messages.to_sentence)
    )
  end
end

SentNotificationsShared.prepend_mod
