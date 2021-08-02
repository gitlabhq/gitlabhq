# frozen_string_literal: true

module Gitlab
  module Graphql
    module TodosProjectPermissionPreloader
      class FieldExtension < ::GraphQL::Schema::FieldExtension
        def after_resolve(value:, memo:, **rest)
          todos = value.to_a

          Preloaders::UserMaxAccessLevelInProjectsPreloader.new(
            todos.map(&:project).compact,
            current_user(rest)
          ).execute

          value
        end

        private

        def current_user(options)
          options.dig(:context, :current_user)
        end
      end
    end
  end
end
