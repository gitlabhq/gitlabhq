# frozen_string_literal: true

module Integrations
  class JiraCloudApp < Integration
    include HasAvatar

    SERVICE_IDS_REGEX = /\A^[A-Za-z0-9=,:]*$\z/
    SERVICE_IDS_LIMIT = 100
    ENVIRONMENT_REGEX = /\A^[A-Za-z0-9,]*$\z/
    AVAILABLE_ENVRIONMENT_NAMES = %w[production staging testing development].freeze

    validate :validate_service_ids_limit, if: :activated?
    validate :validate_deployment_gating_environments, if: :activated?
    validate :validate_valid_deployment_gating_input, if: :activated?
    validates :jira_cloud_app_service_ids, allow_blank: true, format: { with: SERVICE_IDS_REGEX }, if: :activated?
    validates :jira_cloud_app_deployment_gating_environments, allow_blank: true, format: { with: ENVIRONMENT_REGEX },
      if: :activated?
    before_validation :format_deployment_gating_environments,
      if: :jira_cloud_app_deployment_gating_environments_changed?

    field :jira_cloud_app_service_ids,
      section: SECTION_TYPE_CONFIGURATION,
      required: false,
      title: -> { s_("JiraCloudApp|Service ID") },
      help: -> {
              s_("JiraCloudApp|Copy and paste your JSM Service ID here. Use comma (,) to separate multiple IDs.")
            }

    field :jira_cloud_app_enable_deployment_gating,
      section: SECTION_TYPE_CONFIGURATION,
      type: :checkbox,
      required: false,
      title: -> { s_('JiraCloudApp|Deployment Gating') },
      checkbox_label: -> { s_('JiraCloudApp|Enable Deployment Gating') },
      help: -> {
              s_('JiraCloudApp|Enable to approve or reject blocked GitLab deployments from Jira Service Management.')
            }

    field :jira_cloud_app_deployment_gating_environments,
      section: SECTION_TYPE_CONFIGURATION,
      required: false,
      title: -> { s_('JiraCloudApp|Environment Tiers') },
      help: -> {
        format(
          s_('JiraCloudApp|Enter the environment (%{names}) where you want to enable deployment gating. ' \
            'Use comma (,) to separate multiple environments.'),
          names: AVAILABLE_ENVRIONMENT_NAMES.join(',')
        )
      }

    def self.title
      s_('JiraCloudApp|GitLab for Jira Cloud app')
    end

    def self.description
      s_('JiraCloudApp|Sync development information to Jira in real time.')
    end

    def self.help
      jira_doc_link_start = format('<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe,
        url: Gitlab::Routing.url_helpers.help_page_path('integration/jira/connect-app.md',
          anchor: 'configure-the-gitlab-for-jira-cloud-app')
      )

      format(
        s_('JiraCloudApp|This integration is enabled automatically when a group is linked in the ' \
          'GitLab for Jira Cloud app and cannot be enabled or disabled through this form. ' \
          "%{jira_doc_link_start}Learn more.%{link_end}"),
        jira_doc_link_start: jira_doc_link_start,
        link_end: '</a>'.html_safe)
    end

    def self.to_param
      'jira_cloud_app'
    end

    def self.supported_events
      []
    end

    def sections
      [
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: s_('JiraCloudApp|Jira Service Management'),
          description: format(
            '%{description}<br><br>%{help}'.html_safe,
            description: s_('Seamlessly create change requests when your team initiates deployments.'),
            help: help
          )
        }
      ]
    end

    override :manual_activation?
    def manual_activation?
      false
    end

    # The form fields of this integration are editable only after the GitLab for Jira Cloud app configuration
    # flow has been completed for a group, which causes the integration to become activated/enabled.
    override :editable?
    def editable?
      activated?
    end

    private

    def validate_service_ids_limit
      return unless jira_cloud_app_service_ids.present?
      return unless jira_cloud_app_service_ids.split(',').size > SERVICE_IDS_LIMIT

      errors.add(
        :jira_cloud_app_service_ids,
        format(
          s_('JiraCloudApp|cannot have more than %{limit} service IDs'),
          limit: SERVICE_IDS_LIMIT
        )
      )
    end

    def format_deployment_gating_environments
      unformatted = jira_cloud_app_deployment_gating_environments
      return if unformatted.nil?

      self.jira_cloud_app_deployment_gating_environments = unformatted.split(',').map(&:strip).uniq.join(',')
    end

    def validate_deployment_gating_environments
      return unless jira_cloud_app_deployment_gating_environments.present?

      return if jira_cloud_app_deployment_gating_environments.split(',').all? do |env|
                  AVAILABLE_ENVRIONMENT_NAMES.include?(env)
                end

      errors.add(
        :jira_cloud_app_deployment_gating_environments,
        format(
          s_('JiraCloudApp|only available environment names: %{names}'),
          names: AVAILABLE_ENVRIONMENT_NAMES.join(',')
        )
      )
    end

    def validate_valid_deployment_gating_input
      return unless jira_cloud_app_enable_deployment_gating
      return if jira_cloud_app_deployment_gating_environments.present?

      errors.add(
        :jira_cloud_app_deployment_gating_environments,
        format(
          s_('JiraCloudApp|environment names should be provided if deployment gating has been enabled'))
      )
    end
  end
end
