# frozen_string_literal: true

module Gitlab
  module Graphql
    module GlobalIDCompatibility
      # TODO: remove this module once the compatibility layer is no longer needed.
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      def coerce_global_id_arguments!(args)
        global_id_arguments = self.class.arguments.values.select do |arg|
          arg.type.is_a?(Class) && arg.type <= ::Types::GlobalIDType
        end

        global_id_arguments.each do |arg|
          k = arg.keyword
          args[k] &&= arg.type.coerce_isolated_input(args[k])
        end
      end
    end
  end
end
