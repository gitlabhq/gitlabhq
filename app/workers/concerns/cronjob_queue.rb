# frozen_string_literal: true

# Concern that sets various Sidekiq settings for workers executed using a
# cronjob.
module CronjobQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :cronjob
    sidekiq_options retry: false
    worker_context project: nil, namespace: nil, user: nil
  end
end
