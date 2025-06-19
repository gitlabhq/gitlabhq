# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts::ModuleNamespace -- Existing Module
  module Errors
    class DisabledError < StandardError
      def initialize(msg: nil)
        super(msg || default_message)
      end

      private

      def default_message
        "ClickHouse analytics database is not enabled"
      end
    end
  end
end
