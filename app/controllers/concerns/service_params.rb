# frozen_string_literal: true

module ServiceParams
  extend ActiveSupport::Concern

  ALLOWED_PARAMS_CE = [
    :active,
    :add_pusher,
    :api_key,
    :api_url,
    :api_version,
    :bamboo_url,
    :branches_to_be_notified,
    :build_key,
    :build_type,
    :ca_pem,
    :channel,
    :channels,
    :color,
    :colorize_messages,
    :comment_on_event_enabled,
    :confidential_issues_events,
    :default_irc_uri,
    :description,
    :device,
    :disable_diffs,
    :drone_url,
    :enable_ssl_verification,
    :external_wiki_url,
    # We're using `issues_events` and `merge_requests_events`
    # in the view so we still need to explicitly state them
    # here. `Service#event_names` would only give
    # `issue_events` and `merge_request_events` (singular!)
    # See app/helpers/services_helper.rb for how we
    # make those event names plural as special case.
    :issues_events,
    :issues_url,
    :jira_issue_transition_id,
    :manual_configuration,
    :merge_requests_events,
    :mock_service_url,
    :namespace,
    :new_issue_url,
    :notify,
    :notify_only_broken_pipelines,
    :password,
    :priority,
    :project_key,
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
    :title,
    :token,
    :type,
    :url,
    :user_key,
    :username,
    :webhook
  ].freeze

  # Parameters to ignore if no value is specified
  FILTER_BLANK_PARAMS = [:password].freeze

  def service_params
    dynamic_params = @service.event_channel_names + @service.event_names # rubocop:disable Gitlab/ModuleWithInstanceVariables
    service_params = params.permit(:id, service: allowed_service_params + dynamic_params)

    if service_params[:service].is_a?(ActionController::Parameters)
      FILTER_BLANK_PARAMS.each do |param|
        service_params[:service].delete(param) if service_params[:service][param].blank?
      end
    end

    service_params
  end

  def allowed_service_params
    ALLOWED_PARAMS_CE
  end
end

ServiceParams.prepend_if_ee('EE::ServiceParams')
