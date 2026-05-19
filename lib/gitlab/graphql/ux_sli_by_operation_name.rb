# frozen_string_literal: true

module Gitlab
  module Graphql
    class UxSliByOperationName
      def self.operation_ux_sli_map
        {}
      end

      def initialize(operation_name)
        @operation_name = operation_name
      end

      attr_reader :operation_name

      def track
        return yield unless experience_id

        Labkit::UserExperienceSli.start(experience_id) { yield }
      end

      private

      def experience_id
        self.class.operation_ux_sli_map[operation_name]
      end
    end
  end
end

Gitlab::Graphql::UxSliByOperationName.prepend_mod
