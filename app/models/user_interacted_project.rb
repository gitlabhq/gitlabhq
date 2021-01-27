# frozen_string_literal: true

class UserInteractedProject < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  belongs_to :user
  belongs_to :project

  validates :project_id, presence: true
  validates :user_id, presence: true

  CACHE_EXPIRY_TIME = 1.day

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

      cached_exists?(**attributes) do
        transaction(requires_new: true) do
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

    private

    def cached_exists?(project_id:, user_id:, &block)
      cache_key = "user_interacted_projects:#{project_id}:#{user_id}"
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY_TIME, &block)
    end
  end
end
