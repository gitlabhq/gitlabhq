# Concern for setting Sidekiq settings for the various CI build workers.
module BuildQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options queue: :build
  end
end
