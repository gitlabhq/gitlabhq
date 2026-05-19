# frozen_string_literal: true

module Types
  module Terraform
    class StateType < BaseObject
      graphql_name 'TerraformState'

      PROTECTION_RULE_EXISTS_BATCH_SIZE = 20

      authorize :read_terraform_state

      connection_type_class Types::CountableConnectionType

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the Terraform state.'

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Name of the Terraform state.'

      field :locked_by_user, Types::UserType,
        null: true,
        description: 'User currently holding a lock on the Terraform state.'

      field :locked_at, Types::TimeType,
        null: true,
        description: 'Timestamp the Terraform state was locked.'

      field :latest_version, Types::Terraform::StateVersionType,
        complexity: 3,
        null: true,
        description: 'Latest version of the Terraform state.'

      field :created_at, Types::TimeType,
        null: false,
        description: 'Timestamp the Terraform state was created.'

      field :updated_at, Types::TimeType,
        null: false,
        description: 'Timestamp the Terraform state was updated.'

      field :deleted_at, Types::TimeType,
        null: true,
        description: 'Timestamp the Terraform state was deleted.'

      field :protection_rule_exists, GraphQL::Types::Boolean,
        null: false,
        experiment: { milestone: '19.0' },
        description: 'Whether a protection rule exists for the Terraform state.'

      def protection_rule_exists
        return false if Feature.disabled?(:protected_terraform_states, object.project)

        BatchLoader::GraphQL.for([object.project_id, object.name]).batch(default_value: false) do |tuples, loader|
          tuples.each_slice(PROTECTION_RULE_EXISTS_BATCH_SIZE) do |projects_and_state_names|
            ::Terraform::StateProtectionRule
              .exists_for_projects_and_state_names(projects_and_state_names)
              .each { |row| loader.call([row['project_id'], row['state_name']], row['protected']) }
          end
        end
      end

      def locked_by_user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.locked_by_user_id).find
      end
    end
  end
end
