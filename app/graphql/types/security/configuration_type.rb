# frozen_string_literal: true

module Types
  module Security
    class ConfigurationType < BaseObject # rubocop: disable Graphql/AuthorizeTypes -- Authorization is done in the resolver
      graphql_name 'SecurityConfiguration'
      description 'Security configuration data for a project.'

      # rubocop:disable GraphQL/ExtractType -- should match legacy structure
      field :auto_devops_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether Auto DevOps is enabled for the project.'

      field :auto_devops_help_page_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to Auto DevOps help documentation.'

      field :auto_devops_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to Auto DevOps settings.'

      field :can_enable_auto_devops,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the current user can enable Auto DevOps.'

      field :can_enable_spp,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the current user can enable secret push protection.'

      field :container_scanning_for_registry_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether container scanning for registry is enabled.'

      field :features,
        [Types::Security::ScanFeatureType],
        null: false,
        description: 'List of security scan features and their configuration status.'

      field :gitlab_ci_history_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to the GitLab CI configuration file history.'

      field :gitlab_ci_present,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether a GitLab CI configuration file exists in the project.'

      field :help_page_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to application security help documentation.'

      field :is_gitlab_com,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether the instance is GitLab.com.'

      field :latest_pipeline_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to the latest pipeline on the default branch.'

      field :license_configuration_source,
        GraphQL::Types::String,
        null: true,
        description: 'Source of license configuration.'

      field :secret_detection_configuration_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to secret detection configuration.'

      field :secret_push_protection_available,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether secret push protection is available at the instance level.'

      field :secret_push_protection_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether secret push protection is enabled for the project.'

      field :secret_push_protection_licensed,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the project has a license for secret push protection.'

      field :security_training_enabled,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether security training is available for the project.'

      field :user_is_project_admin,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the current user has admin permissions for security testing.'

      field :validity_checks_available,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether secret detection validity checks are available.'

      field :validity_checks_enabled,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether secret detection validity checks are enabled.'

      field :vulnerability_training_docs_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to vulnerability training documentation.'

      field :upgrade_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to upgrade security features.'

      field :group_full_path,
        GraphQL::Types::String,
        null: true,
        description: 'Full path of the root ancestor group.'

      field :can_apply_profiles,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the current user can apply security profiles.'

      field :can_read_attributes,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the current user can read security attributes.'

      field :can_manage_attributes,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the current user can manage security attributes.'

      field :security_scan_profiles_licensed,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the project has a license for security scan profiles.'

      field :group_manage_attributes_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to manage group security attributes.'

      field :max_tracked_refs,
        GraphQL::Types::Int,
        null: true,
        description: 'Maximum number of refs that can be tracked for security scanning.'
      # rubocop:enable GraphQL/ExtractType
    end
  end
end

Types::Security::ConfigurationType.prepend_mod_with('Types::Security::ConfigurationType')
