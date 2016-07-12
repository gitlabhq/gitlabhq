module ServiceParams
  extend ActiveSupport::Concern

  ALLOWED_PARAMS = [:title, :token, :type, :active, :api_key, :api_url, :api_version, :subdomain,
                    :room, :recipients, :project_url, :webhook,
                    :user_key, :device, :priority, :sound, :bamboo_url, :username, :password,
                    :build_key, :server, :teamcity_url, :drone_url, :build_type,
                    :description, :issues_url, :new_issue_url, :restrict_to_branch, :channel,
                    :colorize_messages, :channels,
                    :push_events, :issues_events, :merge_requests_events, :tag_push_events,
                    :note_events, :build_events, :wiki_page_events,
                    :notify_only_broken_builds, :add_pusher,
                    :send_from_committer_email, :disable_diffs, :external_wiki_url,
                    :notify, :color,
                    :server_host, :server_port, :default_irc_uri, :enable_ssl_verification,
                    :jira_issue_transition_id]

  # Parameters to ignore if no value is specified
  FILTER_BLANK_PARAMS = [:password]

  def application_services_params
    dynamic_params = []
    dynamic_params.concat(@service.event_channel_names)

    application_services_params = params.permit(:id, service: ALLOWED_PARAMS + dynamic_params)

    if application_services_params[:service].is_a?(Hash)
      FILTER_BLANK_PARAMS.each do |param|
        application_services_params[:service].delete(param) if application_services_params[:service][param].blank?
      end
    end

    application_services_params
  end
end
