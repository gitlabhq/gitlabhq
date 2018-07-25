# frozen_string_literal: true

# Concern for enabling a few lines of exception backtraces in Sidekiq
module ExceptionBacktrace
  extend ActiveSupport::Concern

  included do
    sidekiq_options backtrace: 5
  end
end
