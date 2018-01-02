##
# Concern for setting Sidekiq settings for the various Gcp clusters workers.
#
module ClusterQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :gcp_cluster
  end
end
