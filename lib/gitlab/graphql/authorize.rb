# frozen_string_literal: true

module Gitlab
  module Graphql
    # Allow fields to declare permissions their objects must have. The field
    # will be set to nil unless all required permissions are present.
    module Authorize
      extend ActiveSupport::Concern

      def self.use(schema_definition)
        schema_definition.instrument(:field, Gitlab::Graphql::Authorize::Instrumentation.new, after_built_ins: true)
      end
    end
  end
end
