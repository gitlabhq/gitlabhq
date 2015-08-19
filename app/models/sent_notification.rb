class SentNotification < ActiveRecord::Base
  belongs_to :project
  belongs_to :noteable, polymorphic: true
  belongs_to :recipient, class_name: "User"

  validate :project, :recipient, :reply_key, presence: true
  validate :reply_key, uniqueness: true

  validates :noteable_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?

  class << self
    def for(reply_key)
      find_by(reply_key: reply_key)
    end

    def record(noteable, recipient_id, reply_key)
      return unless reply_key

      noteable_id = nil
      commit_id = nil
      if noteable.is_a?(Commit)
        commit_id = noteable.id
      else
        noteable_id = noteable.id
      end

      create(
        project:        noteable.project,
        noteable_type:  noteable.class.name,
        noteable_id:    noteable_id,
        commit_id:      commit_id,
        recipient_id:   recipient_id,
        reply_key:      reply_key
      )
    end
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
end
