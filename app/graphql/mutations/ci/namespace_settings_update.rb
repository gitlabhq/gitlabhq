# frozen_string_literal: true

module Mutations
  module Ci
    class NamespaceSettingsUpdate < BaseMutation
      graphql_name 'NamespaceSettingsUpdate'

      include ResolvesNamespace

      authorize :maintainer_access

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the namespace the settings belong to.'
      argument :pipeline_variables_default_role, ::Types::Ci::PipelineVariablesDefaultRoleTypeEnum,
        required: false,
        description: copy_field_description(Types::Ci::NamespaceSettingsType, :pipeline_variables_default_role)

      field :ci_cd_settings,
        Types::Ci::NamespaceSettingsType,
        null: false,
        description: 'Namespace CI/CD settings after mutation.'

      def resolve(full_path:, **args)
        namespace = authorized_find!(full_path)
        settings = namespace.namespace_settings

        service_response = ::Ci::NamespaceSettings::UpdateService
          .new(settings, args)
          .execute

        {
          ci_cd_settings: settings,
          errors: service_response.errors
        }
      end

      private

      def find_object(full_path)
        resolve_namespace(full_path: full_path)
      end
    end
  end
end
