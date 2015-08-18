class SentNotification < ActiveRecord::Base
  belongs_to :project
  belongs_to :noteable, polymorphic: true
  belongs_to :recipient, class_name: "User"

  validate :project, :recipient, :reply_key, presence: true
  validate :reply_key, uniqueness: true

  validates :noteable_id, presence: true, if: ->(n) { n.noteable_type.present? && n.noteable_type != 'Commit' }
  validates :commit_id, presence: true, if: ->(n) { n.noteable_type == 'Commit' }

  def self.for(reply_key)
    find_by(reply_key: reply_key)
  end

  def for_commit?
    noteable_type == "Commit"
  end

  def noteable
    if for_commit?
      project.commit(commit_id)
    else
      super
    end
  rescue
    nil
  end
end
