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
        title: -> { s_('Observability|Explore telemetry data') }
      },
      'datasources' => {
        path: '/datasources',
        title: -> { s_('Observability|Data sources') }
      }
    }.freeze

    def observability_iframe_src(group)
      Gitlab::Observability.build_full_url(group, params[:observability_path],
        observability_config_for(params).fetch(:path))
    end

    def observability_page_title
      observability_config_for(params).fetch(:title).call
    end

    private

    def observability_config_for(params)
      ACTION_TO_PATH.fetch(params[:action], ACTION_TO_PATH['dashboards'])
    end
  end
end
