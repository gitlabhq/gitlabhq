# frozen_string_literal: true

module Mutations
  module Import
    module SourceUsers
      class KeepAllAsPlaceholder < BaseMutation
        graphql_name 'ImportSourceUserKeepAllAsPlaceholder'

        argument :namespace_id, Types::GlobalIDType[::Namespace],
          required: true,
          description: 'Global ID of the namespace.'

        field :updated_import_source_user_count,
          GraphQL::Types::Int,
          null: true,
          description: "Number of successfully updated mappings of users on source instance to their destination users."

        authorize :admin_namespace

        def resolve(args)
          if Feature.disabled?(:importer_user_mapping, current_user)
            raise_resource_not_available_error! '`importer_user_mapping` feature flag is disabled.'
          end

          namespace = authorized_find!(id: args[:namespace_id])
          result = ::Import::SourceUsers::KeepAllAsPlaceholderService.new(namespace, current_user: current_user).execute

          { updated_import_source_user_count: result.payload, errors: result.errors }
        end
      end
    end
  end
end
