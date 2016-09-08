module ServiceParams
  extend ActiveSupport::Concern

  ALLOWED_PARAMS = [:title, :token, :type, :active, :api_key, :api_url, :api_version, :subdomain,
                    :room, :recipients, :project_url, :webhook,
                    :user_key, :device, :priority, :sound, :bamboo_url, :username, :password,
                    :build_key, :server, :teamcity_url, :drone_url, :build_type,
                    :description, :issues_url, :new_issue_url, :restrict_to_branch, :channel,
                    :colorize_messages, :channels,
                    # We're using `issues_events` and `merge_requests_events`
                    # in the view so we still need to explicitly state them
                    # here. `Service#event_names` would only give
                    # `issue_events` and `merge_request_events` (singular!)
                    # See app/helpers/services_helper.rb for how we
                    # make those event names plural as special case.
                    :issues_events, :confidential_issues_events, :merge_requests_events,
                    :notify_only_broken_builds, :notify_only_broken_pipelines,
                    :add_pusher, :send_from_committer_email, :disable_diffs,
                    :external_wiki_url, :notify, :color,
                    :server_host, :server_port, :default_irc_uri, :enable_ssl_verification,
                    :jira_issue_transition_id,

                    ## EE Specific
                    :multiproject_enabled, :pass_unstable,
                    :jenkins_url, :project_name]

  # Parameters to ignore if no value is specified
  FILTER_BLANK_PARAMS = [:password]

  def service_params
    dynamic_params = @service.event_channel_names + @service.event_names
    service_params = params.permit(:id, service: ALLOWED_PARAMS + dynamic_params)

    if service_params[:service].is_a?(Hash)
      FILTER_BLANK_PARAMS.each do |param|
        service_params[:service].delete(param) if service_params[:service][param].blank?
      end
    end

    service_params
  end
end
