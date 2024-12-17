# frozen_string_literal: true

class SentNotification < ApplicationRecord
  include EachBatch

  belongs_to :project
  belongs_to :noteable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :recipient, class_name: "User"
  belongs_to :issue_email_participant

  validates :recipient, presence: true
  validates :reply_key, presence: true, uniqueness: true
  validates :noteable_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?
  validates :in_reply_to_discussion_id, format: { with: /\A\h{40}\z/, allow_nil: true }
  validate :note_valid

  class << self
    def reply_key
      SecureRandom.hex(16)
    end

    def for(reply_key)
      find_by(reply_key: reply_key)
    end

    def record(noteable, recipient_id, reply_key = self.reply_key, attrs = {})
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

      # Non-sticky write is used as `.record` is only used in ActionMailer
      # where there are no queries to SentNotification.
      ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
        create(attrs)
      end
    end

    def record_note(note, recipient_id, reply_key = self.reply_key, attrs = {})
      attrs[:in_reply_to_discussion_id] = note.discussion_id if note.part_of_discussion? || note.can_be_discussion_note?

      record(note.noteable, recipient_id, reply_key, attrs)
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
    self.reply_key
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
