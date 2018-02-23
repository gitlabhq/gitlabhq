class UserContributedProjects < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :project, presence: true
  validates :user, presence: true

  CACHE_EXPIRY_TIME = 1.day

  def self.track(event)
    # For events without a project, we simply don't care.
    # An example of this is the creation of a snippet (which
    # is not related to any project).
    return unless event.project

    # This is a precaution because the cache lookup
    # will work just fine without an author.
    #
    # However, this should never happen (tm).
    raise 'event#author not present unexpectedly' unless event.author

    attributes = {
      project_id: event.project_id,
      user_id: event.author_id
    }

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
