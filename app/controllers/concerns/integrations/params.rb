# frozen_string_literal: true

module Integrations
  module Params
    extend ActiveSupport::Concern

    ALLOWED_PARAMS_CE = [
      :active,
      :add_pusher,
      :alert_events,
      :api_key,
      :api_url,
      :bamboo_url,
      :branches_to_be_notified,
      :labels_to_be_notified,
      :labels_to_be_notified_behavior,
      :build_key,
      :build_type,
      :ca_pem,
      :channel,
      :channels,
      :color,
      :colorize_messages,
      :comment_on_event_enabled,
      :comment_detail,
      :confidential_issues_events,
      :confluence_url,
      :datadog_site,
      :datadog_env,
      :datadog_service,
      :default_irc_uri,
      :device,
      :disable_diffs,
      :drone_url,
      :enable_ssl_verification,
      :external_wiki_url,
      :google_iap_service_account_json,
      :google_iap_audience_client_id,
      :inherit_from_id,
      # We're using `issues_events` and `merge_requests_events`
      # in the view so we still need to explicitly state them
      # here. `Service#event_names` would only give
      # `issue_events` and `merge_request_events` (singular!)
      # See app/helpers/services_helper.rb for how we
      # make those event names plural as special case.
      :issues_events,
      :issues_url,
      :jenkins_url,
      :jira_issue_transition_automatic,
      :jira_issue_transition_id,
      :manual_configuration,
      :merge_requests_events,
      :mock_service_url,
      :namespace,
      :new_issue_url,
      :notify_only_broken_pipelines,
      :password,
      :priority,
      :project_key,
      :project_name,
      :project_url,
      :recipients,
      :restrict_to_branch,
      :room,
      :send_from_committer_email,
      :server,
      :server_host,
      :server_port,
      :sound,
      :subdomain,
      :teamcity_url,
      :token,
      :type,
      :url,
      :user_key,
      :username,
      :webhook
    ].freeze

    # Parameters to ignore if no value is specified
    FILTER_BLANK_PARAMS = [:password].freeze

    def integration_params
      dynamic_params = @integration.event_channel_names + @integration.event_names # rubocop:disable Gitlab/ModuleWithInstanceVariables
      allowed = allowed_integration_params + dynamic_params
      return_value = params.permit(:id, integration: allowed, service: allowed)
      return_value[:integration] ||= return_value.delete(:service)
      param_values = return_value[:integration]

      if param_values.is_a?(ActionController::Parameters)
        FILTER_BLANK_PARAMS.each do |param|
          param_values.delete(param) if param_values[param].blank?
        end
      end

      return_value
    end

    def allowed_integration_params
      ALLOWED_PARAMS_CE
    end
  end
end

Integrations::Params.prepend_mod_with('Integrations::Params')
