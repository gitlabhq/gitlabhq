##
# Concern for setting Sidekiq settings for the various Gcp clusters workers.
#
module ClusterQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :manage_cluster
  end
end
