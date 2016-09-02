class Moderation < ActiveRecord::Base
  belongs_to :project, class_name: 'Project'
  belongs_to :reverted_by, class_name: 'Moderation'
  belongs_to :moderator, class_name: 'User'
  belongs_to :moderated, class_name: 'User'
  belongs_to :subject, polymorphic: true

  REVERT = 0
  LOCK_ISSUE = 1

  def self.active
    now = Time.now
    where(reverted_by: nil).where('ends_at > ?', Time.now)
  end

  def self.for_project(project)
    where(project: project)
  end

  def revert!
    reversion = Moderation.create do |m|
      m.type = REVERT
      m.subject = self
      m.project = self.project
    end

    self.update_attributes(reverted_by: reversion)
  end


end
