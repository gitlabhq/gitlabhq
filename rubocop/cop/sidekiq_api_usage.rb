# frozen_string_literal: true

module RuboCop
  module Cop
    class SidekiqApiUsage < RuboCop::Cop::Base
      MSG = 'Refrain from directly using Sidekiq APIs.' \
          'Only permitted in migrations, administrations and Sidekiq middlewares.'

      ALLOWED_WORKER_METHODS = [
        :skipping_transaction_check,
        :raise_inside_transaction_exception,
        :raise_exception_for_being_inside_a_transaction?
      ].freeze

      def_node_matcher :using_sidekiq_api?, <<~PATTERN
        (send (const (const nil? :Sidekiq) $_  ) $... )
      PATTERN

      def on_send(node)
        using_sidekiq_api?(node) do |klass, methods_called|
          next if klass == :Testing

          # allow methods defined in config/initializers/forbid_sidekiq_in_transactions.rb
          next if klass == :Worker && ALLOWED_WORKER_METHODS.include?(methods_called[0])

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
