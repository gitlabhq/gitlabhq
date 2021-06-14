# frozen_string_literal: true

module Mutations
  module Ci
    class CiCdSettingsUpdate < BaseMutation
      include FindsProject

      graphql_name 'CiCdSettingsUpdate'

      authorize :admin_project

      argument :full_path, GraphQL::ID_TYPE,
        required: true,
        description: 'Full Path of the project the settings belong to.'

      argument :keep_latest_artifact, GraphQL::BOOLEAN_TYPE,
        required: false,
        description: 'Indicates if the latest artifact should be kept for this project.'

      argument :job_token_scope_enabled, GraphQL::BOOLEAN_TYPE,
        required: false,
        description: 'Indicates CI job tokens generated in this project have restricted access to resources.'

      field :ci_cd_settings,
        Types::Ci::CiCdSettingType,
        null: false,
        description: 'The CI/CD settings after mutation.'

      def resolve(full_path:, **args)
        project = authorized_find!(full_path)
        settings = project.ci_cd_settings
        settings.update(args)

        {
          ci_cd_settings: settings,
          errors: errors_on_object(settings)
        }
      end
    end
  end
end

Mutations::Ci::CiCdSettingsUpdate.prepend_mod_with('Mutations::Ci::CiCdSettingsUpdate')
