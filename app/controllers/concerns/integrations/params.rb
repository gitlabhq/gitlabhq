# frozen_string_literal: true

module Integrations
  module Params
    extend ActiveSupport::Concern

    ALLOWED_PARAMS_CE = [
      :app_store_issuer_id,
      :app_store_key_id,
      :app_store_private_key,
      :app_store_private_key_file_name,
      :app_store_protected_refs,
      :active,
      :alert_events,
      :api_key,
      :api_token,
      :api_url,
      :archive_trace_events,
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
      :datadog_tags,
      :datadog_ci_visibility,
      :default_irc_uri,
      :device,
      :disable_diffs,
      :diffblue_access_token_name,
      :diffblue_access_token_secret,
      :diffblue_license_key,
      :drone_url,
      :enable_ssl_verification,
      :exclude_service_accounts,
      :external_wiki_url,
      :google_iap_service_account_json,
      :google_iap_audience_client_id,
      :google_play_protected_refs,
      :group_confidential_mention_events,
      :group_mention_events,
      :hostname,
      :incident_events,
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
      :jira_auth_type,
      :jira_issue_prefix,
      :jira_issue_regex,
      :jira_issue_transition_automatic,
      :jira_issue_transition_id,
      :jira_cloud_app_service_ids,
      :jira_cloud_app_enable_deployment_gating,
      :jira_cloud_app_deployment_gating_environments,
      :manual_configuration,
      :merge_requests_events,
      :mock_service_url,
      :namespace,
      :new_issue_url,
      :notify_only_broken_pipelines,
      :package_name,
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
      :service_account_key,
      :service_account_key_file_name,
      :sound,
      :subdomain,
      :teamcity_url,
      :thread,
      :token,
      :type,
      :url,
      :user_key,
      :username,
      :webhook,
      :zentao_product_xid
    ].freeze

    def integration_params
      dynamic_params = integration.event_channel_names + integration.event_names
      allowed = allowed_integration_params + dynamic_params
      return_value = params.permit(:id, integration: allowed, service: allowed)
      return_value[:integration] ||= return_value.delete(:service)
      param_values = return_value[:integration]

      if param_values.is_a?(ActionController::Parameters)
        if %w[update test].include?(action_name) && integration.chat?
          param_values.delete('webhook') if param_values['webhook'] == Base::ChatNotification::SECRET_MASK

          if integration.try(:mask_configurable_channels?)
            integration.event_channel_names.each do |channel|
              param_values.delete(channel) if param_values[channel] == Base::ChatNotification::SECRET_MASK
            end
          end
        end

        integration.secret_fields.each do |param|
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
