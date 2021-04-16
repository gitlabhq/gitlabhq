# frozen_string_literal: true

class SentNotification < ApplicationRecord
  serialize :position, Gitlab::Diff::Position # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :project
  belongs_to :noteable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :recipient, class_name: "User"

  validates :recipient, presence: true
  validates :reply_key, presence: true, uniqueness: true
  validates :noteable_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?
  validates :in_reply_to_discussion_id, format: { with: /\A\h{40}\z/, allow_nil: true }
  validate :note_valid

  after_save :keep_around_commit, if: :for_commit?

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

      create(attrs)
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
      project.commit(commit_id) rescue nil
    else
      super
    end
  end

  def position=(new_position)
    if new_position.is_a?(String)
      new_position = Gitlab::Json.parse(new_position) rescue nil
    end

    if new_position.is_a?(Hash)
      new_position = new_position.with_indifferent_access
      new_position = Gitlab::Diff::Position.new(new_position)
    else
      new_position = nil
    end

    super(new_position)
  end

  def to_param
    self.reply_key
  end

  def create_reply(message, dryrun: false)
    klass = dryrun ? Notes::BuildService : Notes::CreateService
    klass.new(self.project, self.recipient, reply_params.merge(note: message)).execute
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

  def keep_around_commit
    project.repository.keep_around(self.commit_id)
  end
end
