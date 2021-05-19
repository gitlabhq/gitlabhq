# frozen_string_literal: true

# Responsible for returning a gitlab-compatible dashboard
# containing info based on a grafana dashboard and datasource.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class GrafanaMetricEmbedService < ::Metrics::Dashboard::BaseEmbedService
      include ReactiveCaching

      SEQUENCE = [
        ::Gitlab::Metrics::Dashboard::Stages::GrafanaFormatter,
        ::Gitlab::Metrics::Dashboard::Stages::PanelIdsInserter
      ].freeze

      self.reactive_cache_key = ->(service) { service.cache_key }
      self.reactive_cache_lease_timeout = 30.seconds
      self.reactive_cache_refresh_interval = 30.minutes
      self.reactive_cache_lifetime = 30.minutes
      self.reactive_cache_work_type = :external_dependency
      self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

      class << self
        # Determines whether the provided params are sufficient
        # to uniquely identify a grafana dashboard.
        def valid_params?(params)
          [
            embedded?(params[:embedded]),
            params[:grafana_url]
          ].all?
        end

        def from_cache(project_id, user_id, grafana_url)
          project = Project.find(project_id)
          user = User.find(user_id) if user_id.present?

          new(project, user, grafana_url: grafana_url)
        end
      end

      def get_dashboard
        with_reactive_cache(*cache_key) { |result| result }
      end

      # Inherits the primary logic from the parent class and
      # maintains the service's API while including ReactiveCache
      def calculate_reactive_cache(*)
        # This is called with explicit parentheses to prevent
        # the params passed to #calculate_reactive_cache from
        # being passed to #get_dashboard (which accepts none)
        ::Metrics::Dashboard::BaseService
          .instance_method(:get_dashboard)
          .bind(self)
          .call() # rubocop:disable Style/MethodCallWithoutArgsParentheses
      end

      def cache_key(*args)
        [project.id, current_user&.id, grafana_url]
      end

      # Required for ReactiveCaching; Usage overridden by
      # self.reactive_cache_worker_finder
      def id
        nil
      end

      private

      def get_raw_dashboard
        raise MissingIntegrationError unless client

        grafana_dashboard = fetch_dashboard
        datasource = fetch_datasource(grafana_dashboard)

        params.merge!(grafana_dashboard: grafana_dashboard, datasource: datasource)

        {}
      end

      def fetch_dashboard
        uid = GrafanaUidParser.new(grafana_url, project).parse
        raise DashboardProcessingError, _('Dashboard uid not found') unless uid

        response = client.get_dashboard(uid: uid)

        parse_json(response.body)
      end

      def fetch_datasource(dashboard)
        name = DatasourceNameParser.new(grafana_url, dashboard).parse
        raise DashboardProcessingError, _('Datasource name not found') unless name

        response = client.get_datasource(name: name)

        parse_json(response.body)
      end

      def grafana_url
        params[:grafana_url]
      end

      def client
        project.grafana_integration&.client
      end

      def allowed?
        Ability.allowed?(current_user, :read_project, project)
      end

      def sequence
        SEQUENCE
      end

      def parse_json(json)
        Gitlab::Json.parse(json, symbolize_names: true)
      rescue JSON::ParserError
        raise DashboardProcessingError, _('Grafana response contains invalid json')
      end
    end

    # Identifies the uid of the dashboard based on url format
    class GrafanaUidParser
      def initialize(grafana_url, project)
        @grafana_url = grafana_url
        @project = project
      end

      def parse
        @grafana_url.match(uid_regex) { |m| m.named_captures['uid'] }
      end

      private

      # URLs are expected to look like https://domain.com/d/:uid/other/stuff
      def uid_regex
        base_url = @project.grafana_integration.grafana_url.chomp('/')

        %r{^(#{Regexp.escape(base_url)}\/d\/(?<uid>.+)\/)}x
      end
    end

    # Identifies the name of the datasource for a dashboard
    # based on the panelId query parameter found in the url.
    #
    # If no panel is specified, defaults to the first valid panel.
    class DatasourceNameParser
      def initialize(grafana_url, grafana_dashboard)
        @grafana_url = grafana_url
        @grafana_dashboard = grafana_dashboard
      end

      def parse
        @grafana_dashboard[:dashboard][:panels]
          .find { |panel| panel_id ? matching_panel?(panel) : valid_panel?(panel) }
          .try(:[], :datasource)
      end

      private

      def panel_id
        query_params[:panelId]
      end

      def query_params
        Gitlab::Metrics::Dashboard::Url.parse_query(@grafana_url)
      end

      def matching_panel?(panel)
        panel[:id].to_s == panel_id
      end

      def valid_panel?(panel)
        ::Grafana::Validator
          .new(@grafana_dashboard, nil, panel, query_params)
          .valid?
      end
    end
  end
end
