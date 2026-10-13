# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class InheritedCiVariableType < BaseObject
      graphql_name 'InheritedCiVariable'
      description 'CI/CD variables a project inherits from its parent group and ancestors.'

      include Gitlab::Utils::StrongMemoize

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the variable.'

      field :key, GraphQL::Types::String,
        null: true,
        description: 'Name of the variable.'

      field :description, GraphQL::Types::String,
        null: true,
        description: 'Description of the variable.'

      field :raw, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is raw.'

      field :variable_type, ::Types::Ci::VariableTypeEnum,
        null: true,
        description: 'Type of the variable.'

      field :environment_scope, GraphQL::Types::String,
        null: true,
        description: 'Scope defining the environments that can use the variable.'

      field :protected, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is protected.'

      field :masked, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is masked.'

      field :hidden, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the variable is hidden.'

      field :group_name, GraphQL::Types::String,
        null: true,
        description: 'Indicates group the variable belongs to.'

      field :group_ci_cd_settings_path, GraphQL::Types::String,
        null: true,
        description: 'Indicates the path to the CI/CD settings of the group the variable belongs to.'

      def group_name
        Gitlab::Graphql::Lazy.with_value(batched_group) { |group| group&.name }
      end

      def group_ci_cd_settings_path
        return unless current_user

        Gitlab::Graphql::Lazy.with_value(batched_group) do |group|
          next unless group && Ability.allowed?(current_user, :admin_cicd_variables, group)

          Gitlab::Routing.url_helpers.group_settings_ci_cd_path(group)
        end
      end

      private

      def batched_group
        BatchLoader::GraphQL.for(object.group_id).batch(key: current_user) do |group_ids, loader, args|
          groups = ::Group.id_in(group_ids).with_route.to_a
          ::Preloaders::GroupPolicyPreloader.new(groups, args[:key]).execute if args[:key]

          groups.each { |group| loader.call(group.id, group) }
        end
      end
      strong_memoize_attr :batched_group
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
