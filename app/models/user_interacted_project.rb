class UserInteractedProject < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :project_id, presence: true
  validates :user_id, presence: true

  CACHE_EXPIRY_TIME = 1.day

  # Schema version required for this model
  REQUIRED_SCHEMA_VERSION = 20180223120443

  class << self
    def track(event)
      # For events without a project, we simply don't care.
      # An example of this is the creation of a snippet (which
      # is not related to any project).
      return unless event.project_id

      attributes = {
        project_id: event.project_id,
        user_id: event.author_id
      }

      cached_exists?(attributes) do
        transaction(requires_new: true) do
          begin
            where(attributes).select(1).first || create!(attributes)
            true # not caching the whole record here for now
          rescue ActiveRecord::RecordNotUnique
            # Note, above queries are not atomic and prone
            # to race conditions (similar like #find_or_create!).
            # In the case where we hit this, the record we want
            # already exists - shortcut and return.
            true
          end
        end
      end
    end

    # Check if we can safely call .track (table exists)
    def available?
      @available_flag ||= ActiveRecord::Migrator.current_version >= REQUIRED_SCHEMA_VERSION # rubocop:disable Gitlab/PredicateMemoization
    end

    # Flushes cached information about schema
    def reset_column_information
      @available_flag = nil
      super
    end

    private

    def cached_exists?(project_id:, user_id:, &block)
      cache_key = "user_interacted_projects:#{project_id}:#{user_id}"
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY_TIME, &block)
    end
  end
end
