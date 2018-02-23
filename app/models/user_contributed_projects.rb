class UserContributedProjects < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :user, presence: true

  CACHE_EXPIRY_TIME = 1.day

  def self.track(event)
    attributes = {project_id: event.project_id, user_id: event.author_id}

    cached_exists?(attributes) do
      begin
        find_or_create_by!(attributes)
        true # not caching the whole record here for now
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end

  private

  def self.cached_exists?(project_id:, user_id:, &block)
    cache_key = "user_contributed_projects:#{project_id}:#{user_id}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY_TIME, &block)
  end
end
