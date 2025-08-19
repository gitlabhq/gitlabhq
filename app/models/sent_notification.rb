# frozen_string_literal: true

class SentNotification < ApplicationRecord
  include EachBatch

  INVALID_NOTEABLE = Class.new(StandardError)
  # Email reply key is in the form: i_<id-64-bit>-k_<32-char-hex-key>-t_<timestamp-64-bit>
  PARTITIONED_REPLY_KEY_REGEX = /i_(?<id>\d{1,19})-k_(?<reply_key>[a-f\d]{32})-t_(?<timestamp>\d{1,19})/
  LEGACY_REPLY_KEY_REGEX = /(?<legacy_key>[a-f\d]{32})/
  FULL_REPLY_KEY_REGEX = /((#{LEGACY_REPLY_KEY_REGEX})|(#{PARTITIONED_REPLY_KEY_REGEX}))/

  belongs_to :project
  belongs_to :noteable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
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
  before_create :ensure_created_at

  class << self
    def reply_key
      SecureRandom.hex(16)
    end

    def for(reply_key)
      return find_by(reply_key: reply_key) if Feature.disabled?(:sent_notifications_partitioned_reply_key, :instance)

      matches = FULL_REPLY_KEY_REGEX.match(reply_key)
      return unless matches

      if matches[:reply_key]
        created_at_from_timestamp = Gitlab::Utils::TimeIntegerConverter.new(matches[:timestamp]).to_time
        find_by(id: matches[:id], reply_key: matches[:reply_key], created_at: created_at_from_timestamp)
      else
        find_by(reply_key: matches[:legacy_key])
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
        reply_key: self.reply_key,

        noteable_type: noteable.class.name,
        noteable_id: noteable_id,
        commit_id: commit_id
      )

      # Non-sticky write is used as `.record` is only used in ActionMailer
      # where there are no queries to SentNotification.
      ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
        create(attrs)
      end
    end

    def record_note(note, recipient_id, attrs = {})
      attrs[:in_reply_to_discussion_id] = note.discussion_id if note.part_of_discussion? || note.can_be_discussion_note?

      record(note.noteable, recipient_id, attrs)
    end
  end

  def partitioned_reply_key
    return reply_key if Feature.disabled?(:sent_notifications_partitioned_reply_key, :instance)

    microseconds = Gitlab::Utils::TimeIntegerConverter.new(created_at).to_i

    "i_#{id}-k_#{reply_key}-t_#{microseconds}"
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

    klass.new(self.project,
      self.recipient,
      params
    ).execute
  end

  private

  # TODO: Remove in 18.1 as this is only necessary while the default is loaded via the migration.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186703#note_2432949624
  def ensure_created_at
    self.created_at = Time.current
  end

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
        _("%{noteable_type} is not supported") % { noteable_type: noteable_type }
      )
    end
  end

  def reply_params
    {
      noteable_type: self.noteable_type,
      noteable_id: self.noteable_id,
      commit_id: self.commit_id,
      in_reply_to_discussion_id: self.in_reply_to_discussion_id
    }
  end

  def note_valid
    note = create_reply('Test', dryrun: true)

    unless note.valid?
      self.errors.add(
        :base, _("Note parameters are invalid: %{errors}") %
          { errors: note.errors.full_messages.to_sentence }
      )
    end
  end
end

SentNotification.prepend_mod
