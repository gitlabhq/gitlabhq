# frozen_string_literal: true

module Groups
  module ObservabilityHelper
    ACTION_TO_PATH = {
      'dashboards' => {
        path: '/',
        title: -> { s_('Observability|Dashboards') }
      },
      'manage' => {
        path: '/dashboards',
        title: -> { s_('Observability|Manage dashboards') }
      },
      'explore' => {
        path: '/explore',
        title: -> { s_('Observability|Explore') }
      },
      'datasources' => {
        path: '/datasources',
        title: -> { s_('Observability|Data sources') }
      }
    }.freeze

    def observability_iframe_src(group)
      # Format: https://observe.gitlab.com/GROUP_ID

      # When running Observability UI in standalone mode (i.e. not backed by Observability Backend)
      # the group-id is not required. This is mostly used for local dev
      base_url = ENV['STANDALONE_OBSERVABILITY_UI'] == 'true' ? observability_url : "#{observability_url}/-/#{group.id}"

      sanitized_path = if params[:observability_path] && sanitize(params[:observability_path]) != ''
                         CGI.unescapeHTML(sanitize(params[:observability_path]))
                       else
                         observability_config_for(params).fetch(:path)
                       end

      "#{base_url}#{sanitized_path}"
    end

    def observability_page_title
      observability_config_for(params).fetch(:title).call
    end

    private

    def observability_url
      Gitlab::Observability.observability_url
    end

    def observability_config_for(params)
      ACTION_TO_PATH.fetch(params[:action], ACTION_TO_PATH['dashboards'])
    end
  end
end
