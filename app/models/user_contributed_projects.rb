class UserContributedProjects < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :user, presence: true

  def self.track(event)
    find_or_create_by!(project: event.project, user: event.author)
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
