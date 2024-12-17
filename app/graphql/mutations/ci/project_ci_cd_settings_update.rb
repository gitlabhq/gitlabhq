# frozen_string_literal: true

module Mutations
  module Ci
    class ProjectCiCdSettingsUpdate < BaseMutation
      graphql_name 'ProjectCiCdSettingsUpdate'

      include FindsProject
      include Gitlab::Utils::StrongMemoize
      include ::Ci::JobToken::InternalEventsTracking

      authorize :admin_project

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full Path of the project the settings belong to.'

      argument :keep_latest_artifact, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates if the latest artifact should be kept for the project.'

      argument :job_token_scope_enabled, GraphQL::Types::Boolean,
        required: false,
        deprecated: {
          reason: 'Outbound job token scope is being removed. This field can now only be set to false',
          milestone: '16.0'
        },
        description: 'Indicates CI/CD job tokens generated in this project ' \
          'have restricted access to other projects.'

      argument :inbound_job_token_scope_enabled, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates CI/CD job tokens generated in other projects ' \
          'have restricted access to this project.'

      argument :push_repository_for_job_token_allowed, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates the ability to push to the original project ' \
          'repository using a job token'

      field :ci_cd_settings,
        Types::Ci::CiCdSettingType,
        null: false,
        description: 'CI/CD settings after mutation.'

      def resolve(full_path:, **args)
        if args[:job_token_scope_enabled]
          raise Gitlab::Graphql::Errors::ArgumentError, 'job_token_scope_enabled can only be set to false'
        end

        settings = project(full_path).ci_cd_settings
        settings.update(args)

        track_job_token_scope_setting_changes(settings, current_user) unless settings.errors.any?

        {
          ci_cd_settings: settings,
          errors: errors_on_object(settings)
        }
      end

      private

      def project(full_path)
        strong_memoize_with(:project, full_path) do
          authorized_find!(full_path)
        end
      end
    end
  end
end

Mutations::Ci::ProjectCiCdSettingsUpdate.prepend_mod_with('Mutations::Ci::ProjectCiCdSettingsUpdate')
