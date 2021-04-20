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

  class_methods do
    # Cronjobs never get scheduled with arguments, so this is safe to
    # override
    def context_for_arguments(_args)
      return if Gitlab::ApplicationContext.current_context_include?(:caller_id)

      Gitlab::ApplicationContext.new(caller_id: "Cronjob")
    end
  end
end
