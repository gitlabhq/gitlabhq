# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectRunnersResolver < RunnersResolver
      type Types::Ci::RunnerType.connection_type, null: true

      def parent_param
        raise 'Expected project missing' unless parent.is_a?(Project)

        { project: parent }
      end
    end
  end
end
