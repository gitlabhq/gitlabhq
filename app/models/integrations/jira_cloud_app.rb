# frozen_string_literal: true

module Integrations
  class JiraCloudApp < Integration
    include HasAvatar

    SERVICE_IDS_REGEX = /\A^[A-Za-z0-9=,:]*$\z/
    SERVICE_IDS_LIMIT = 100

    validate :validate_service_ids_limit, if: :activated?
    validates :jira_cloud_app_service_ids, allow_blank: true, format: { with: SERVICE_IDS_REGEX }, if: :activated?

    field :jira_cloud_app_service_ids,
      section: SECTION_TYPE_CONFIGURATION,
      required: false,
      title: -> { s_("JiraCloudApp|Service ID") },
      help: -> {
              s_("JiraCloudApp|Copy and paste your JSM Service ID here. Use comma (,) to separate multiple IDs.")
            }

    def self.title
      s_('JiraCloudApp|GitLab for Jira Cloud app')
    end

    def self.description
      s_('JiraCloudApp|Sync development information to Jira in real time.')
    end

    def self.help
      jira_doc_link_start = format('<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe,
        url: Gitlab::Routing.url_helpers.help_page_path('integration/jira/connect-app',
          anchor: 'configure-jira-service-management')
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

    override :show_active_box?
    def show_active_box?
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
  end
end
