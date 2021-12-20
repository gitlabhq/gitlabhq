# frozen_string_literal: true

module Transactions
  extend ActiveSupport::Concern

  class_methods do
    # inside_transaction? will return true if the caller is running within a
    # transaction. Handles special cases when running inside a test environment,
    # where tests may be wrapped in transactions
    def inside_transaction?
      base = Rails.env.test? ? open_transactions_baseline.to_i : 0

      connection.open_transactions > base
    end

    # These methods that access @open_transactions_baseline are not thread-safe.
    # These are fine though because we only call these in RSpec's main thread.
    # If we decide to run specs multi-threaded, we would need to use something
    # like ThreadGroup to keep track of this value
    def set_open_transactions_baseline
      @open_transactions_baseline = connection.open_transactions
    end

    def reset_open_transactions_baseline
      @open_transactions_baseline = 0
    end

    def open_transactions_baseline
      return unless Rails.env.test?

      if @open_transactions_baseline.nil?
        return self == ApplicationRecord ? nil : superclass.open_transactions_baseline
      end

      @open_transactions_baseline
    end
  end
end
