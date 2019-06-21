# frozen_string_literal: true

module Gitlab
  module Graphql
    # Allow fields to declare permissions their objects must have. The field
    # will be set to nil unless all required permissions are present.
    module CallsGitaly
      extend ActiveSupport::Concern

      def self.use(schema_definition)
        schema_definition.instrument(:field, Gitlab::Graphql::CallsGitaly::Instrumentation.new, after_built_ins: true)
      end
    end
  end
end
