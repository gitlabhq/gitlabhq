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
        where(attributes).exists? || UserInteractedProject.insert_all([attributes], unique_by: %w(project_id user_id))
        true
      end
    end

    private

    def cached_exists?(project_id:, user_id:, &block)
      cache_key = "user_interacted_projects:#{project_id}:#{user_id}"
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY_TIME, &block)
    end
  end
end
