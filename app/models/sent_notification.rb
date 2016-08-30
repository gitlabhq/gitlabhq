class SentNotification < ActiveRecord::Base
  serialize :position, Gitlab::Diff::Position

  belongs_to :project
  belongs_to :noteable, polymorphic: true
  belongs_to :recipient, class_name: "User"

  validates :project, :recipient, :reply_key, presence: true
  validates :reply_key, uniqueness: true
  validates :noteable_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?
  validate :note_valid

  after_save :keep_around_commit

  class << self
    def reply_key
      SecureRandom.hex(16)
    end

    def for(reply_key)
      find_by(reply_key: reply_key)
    end

    def record(noteable, recipient_id, reply_key, attrs = {})
      return unless reply_key

      noteable_id = nil
      commit_id = nil
      if noteable.is_a?(Commit)
        commit_id = noteable.id
      else
        noteable_id = noteable.id
      end

      attrs.reverse_merge!(
        project:        noteable.project,
        noteable_type:  noteable.class.name,
        noteable_id:    noteable_id,
        commit_id:      commit_id,
        recipient_id:   recipient_id,
        reply_key:      reply_key
      )

      create(attrs)
    end

    def record_note(note, recipient_id, reply_key, attrs = {})
      if note.diff_note?
        attrs[:note_type] = note.type

        attrs.merge!(note.diff_attributes)
      end

      record(note.noteable, recipient_id, reply_key, attrs)
    end
  end

  def unsubscribable?
    !for_commit?
  end

  def for_commit?
    noteable_type == "Commit"
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
      new_position = JSON.parse(new_position) rescue nil
    end

    if new_position.is_a?(Hash)
      new_position = new_position.with_indifferent_access
      new_position = Gitlab::Diff::Position.new(new_position)
    end

    super(new_position)
  end

  def to_param
    self.reply_key
  end

  def note_attributes
    {
      project:        self.project,
      author:         self.recipient,
      type:           self.note_type,
      noteable_type:  self.noteable_type,
      noteable_id:    self.noteable_id,
      commit_id:      self.commit_id,
      line_code:      self.line_code,
      position:       self.position.to_json
    }
  end

  def create_note(note)
    Notes::CreateService.new(
      self.project,
      self.recipient,
      self.note_attributes.merge(note: note)
    ).execute
  end

  private

  def note_valid
    Note.new(note_attributes.merge(note: "Test")).valid?
  end

  def keep_around_commit
    project.repository.keep_around(self.commit_id)
  end
end
