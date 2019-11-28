# frozen_string_literal: true

# Responsible for returning a gitlab-compatible dashboard
# containing info based on a grafana dashboard and datasource.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class GrafanaMetricEmbedService < ::Metrics::Dashboard::BaseService
      include ReactiveCaching

      SEQUENCE = [
        ::Gitlab::Metrics::Dashboard::Stages::GrafanaFormatter
      ].freeze

      self.reactive_cache_key = ->(service) { service.cache_key }
      self.reactive_cache_lease_timeout = 30.seconds
      self.reactive_cache_refresh_interval = 30.minutes
      self.reactive_cache_lifetime = 30.minutes
      self.reactive_cache_worker_finder = ->(_id, *args) { from_cache(*args) }

      class << self
        # Determines whether the provided params are sufficient
        # to uniquely identify a grafana dashboard.
        def valid_params?(params)
          [
            params[:embedded],
            params[:grafana_url]
          ].all?
        end

        def from_cache(project_id, user_id, grafana_url)
          project = Project.find(project_id)
          user = User.find(user_id)

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
        [project.id, current_user.id, grafana_url]
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
        raise DashboardProcessingError.new('Dashboard uid not found') unless uid

        response = client.get_dashboard(uid: uid)

        parse_json(response.body)
      end

      def fetch_datasource(dashboard)
        name = DatasourceNameParser.new(grafana_url, dashboard).parse
        raise DashboardProcessingError.new('Datasource name not found') unless name

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
        JSON.parse(json, symbolize_names: true)
      rescue JSON::ParserError
        raise DashboardProcessingError.new('Grafana response contains invalid json')
      end
    end

    # Identifies the uid of the dashboard based on url format
    class GrafanaUidParser
      def initialize(grafana_url, project)
        @grafana_url, @project = grafana_url, project
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
    # based on the panelId query parameter found in the url
    class DatasourceNameParser
      def initialize(grafana_url, grafana_dashboard)
        @grafana_url, @grafana_dashboard = grafana_url, grafana_dashboard
      end

      def parse
        @grafana_dashboard[:dashboard][:panels]
          .find { |panel| panel[:id].to_s == query_params[:panelId] }
          .try(:[], :datasource)
      end

      private

      def query_params
        Gitlab::Metrics::Dashboard::Url.parse_query(@grafana_url)
      end
    end
  end
end
