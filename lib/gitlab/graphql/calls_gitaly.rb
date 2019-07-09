# frozen_string_literal: true

module Gitlab
  module Graphql
    # Wraps the field resolution to count Gitaly calls before and after.
    # Raises an error if the field calls Gitaly but hadn't declared such.
    module CallsGitaly
      extend ActiveSupport::Concern

      def self.use(schema_definition)
        schema_definition.instrument(:field, Gitlab::Graphql::CallsGitaly::Instrumentation.new, after_built_ins: true)
      end
    end
  end
end
