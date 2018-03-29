# Concern for setting Sidekiq settings for the various GitLab ObjectStorage workers.
module ObjectStorageQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :object_storage
  end
end
