# frozen_string_literal: true

module Mutations
  module Ci
    class ProjectCiCdSettingsUpdate < BaseMutation
      graphql_name 'ProjectCiCdSettingsUpdate'

      include FindsProject
      include Gitlab::Utils::StrongMemoize

      authorize :admin_project

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full Path of the project the settings belong to.'

      argument :group_runners_enabled, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates whether group runners are enabled for the project.'

      argument :keep_latest_artifact, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates whether the latest artifact should be kept for the project.'

      argument :job_token_scope_enabled, GraphQL::Types::Boolean,
        required: false,
        deprecated: {
          reason: 'Outbound job token scope is being removed. This field can now only be set to false',
          milestone: '16.0'
        },
        description: 'Indicates whether CI/CD job tokens generated in this project ' \
          'have restricted access to other projects.'

      argument :inbound_job_token_scope_enabled, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates whether CI/CD job tokens generated in other projects ' \
          'have restricted access to this project.'

      argument :push_repository_for_job_token_allowed, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates the ability to push to the original project ' \
          'repository using a job token'

      argument :pipeline_variables_minimum_override_role,
        GraphQL::Types::String,
        required: false,
        description: 'Minimum role required to set variables when creating a pipeline or running a job.'

      field :ci_cd_settings,
        Types::Ci::CiCdSettingType,
        null: false,
        description: 'CI/CD settings after mutation.'

      def resolve(full_path:, **args)
        if args[:job_token_scope_enabled]
          raise Gitlab::Graphql::Errors::ArgumentError, 'job_token_scope_enabled can only be set to false'
        end

        project = authorized_find!(full_path)

        response = ::Projects::UpdateService.new(
          project,
          current_user,
          project_update_params(project, **args)
        ).execute

        settings = project.ci_cd_settings

        if response[:status] == :success
          {
            ci_cd_settings: settings,
            errors: errors_on_object(settings)
          }
        else
          {
            ci_cd_settings: settings,
            errors: [response[:message]]
          }
        end
      end

      private

      def project_update_params(_project, **args)
        {
          group_runners_enabled: args[:group_runners_enabled],
          keep_latest_artifact: args[:keep_latest_artifact],
          ci_outbound_job_token_scope_enabled: args[:job_token_scope_enabled],
          ci_inbound_job_token_scope_enabled: args[:inbound_job_token_scope_enabled],
          ci_push_repository_for_job_token_allowed: args[:push_repository_for_job_token_allowed],
          restrict_user_defined_variables: args[:restrict_user_defined_variables],
          ci_pipeline_variables_minimum_override_role: args[:pipeline_variables_minimum_override_role]
        }.compact
      end
    end
  end
end

Mutations::Ci::ProjectCiCdSettingsUpdate.prepend_mod_with('Mutations::Ci::ProjectCiCdSettingsUpdate')
