# Concern for enabling a few lines of exception backtraces in Sidekiq
module BuildQueue
  extend ActiveSupport::Concern

  included do
    sidekiq_options backtrace: 5
  end
end
