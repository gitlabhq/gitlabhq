# frozen_string_literal: true

# Concern for setting Sidekiq settings for the various repository check workers.
module RepositoryCheckQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :repository_check
    sidekiq_options retry: false
    feature_category :source_code_management
  end
end
