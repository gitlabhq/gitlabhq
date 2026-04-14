# frozen_string_literal: true

module Observability
  class ObservabilityPresenter
    include Gitlab::Utils::StrongMemoize
    include ReactiveCaching

    self.reactive_cache_key = ->(presenter) { ['observability_presenter', presenter.id] }
    self.reactive_cache_refresh_interval = 30.seconds
    self.reactive_cache_lifetime = 10.minutes
    self.reactive_cache_work_type = :external_dependency
    self.reactive_cache_worker_finder = ->(id, *_args) do
      # Since ObservabilityPresenter is not an ActiveRecord model, we need to reconstruct it
      group = Group.id_in([id]).first
      new(group, nil) if group
    end

    SEGMENT_TITLES = {
      'services' => 'Observability|Services',
      'service-map' => 'Observability|Service map',
      'trace' => 'Observability|Traces',
      'traces' => 'Observability|Traces',
      'traces-explorer' => 'Observability|Traces',
      'logs' => 'Observability|Logs',
      'logs-explorer' => 'Observability|Logs',
      'dashboard' => 'Observability|Dashboard',
      'alerts' => 'Observability|Alerts',
      'exceptions' => 'Observability|Exceptions',
      'metrics-explorer' => 'Observability|Metrics explorer',
      'infrastructure-monitoring' => 'Observability|Infrastructure monitoring',
      'messaging-queues' => 'Observability|Messaging queues',
      'api-monitoring' => 'Observability|API monitoring',
      'settings' => 'Observability|Notification channels'
    }.freeze

    PATHS = %w[
      services
      services/:servicename
      services/:servicename/top-level-operations
      service-map
      trace
      trace/:id
      traces-explorer
      traces/saved-views
      traces/funnels
      traces/funnels/:funnelId
      logs
      logs/logs-explorer
      logs/old-logs-explorer
      logs/logs-explorer/live
      logs/pipelines
      logs/saved-views
      logs-explorer/index-fields
      dashboard
      dashboard/:dashboardId
      dashboard/:dashboardId/:widgetId
      alerts
      alerts/edit
      alerts/new
      alerts/history
      alerts/overview
      exceptions
      metrics-explorer/summary
      metrics-explorer/explorer
      metrics-explorer/views
      infrastructure-monitoring/hosts
      infrastructure-monitoring/kubernetes
      messaging-queues
      messaging-queues/overview
      messaging-queues/kafka
      messaging-queues/kafka/detail
      messaging-queues/celery-task
      api-monitoring
      api-monitoring/explorer
      settings/channels
    ].freeze

    ALLOWED_QUERY_PARAMS = %w[
      startTime
      endTime
      relativeTime
      compositeQuery
      panelTypes
      resourceAttribute
      ruleId
      alertType
      ruleType
      tab
      timelineFilter
      viewAllTopContributors
      order
      offset
      page
      pageSize
      pagination
      search
      columnKey
      selectedExplorerView
      viewName
      viewKey
      activeLogId
      options
      limit
      expandedWidgetId
      graphType
      widgetId
      variables
      summaryFilters
      orderParam
      exceptionType
      serviceName
      isMetricDetailsOpen
      isInspectModalOpen
      selectedMetricName
      hostName
      view
      hostsFilters
      logFilters
      tracesFilters
      eventsFilters
      mqServiceView
      selectedTimelineQuery
      configDetail
      consumerGrp
      topic
      partition
      apiMonitoringParams
    ].freeze

    QUERY_STRING_MAX_BYTES = 4096
    PARAM_VALUE_MAX_BYTES  = 1024

    # Pre-compiled regexes - one per PATHS template pattern.
    # A template segment starting with `:` matches any non-empty, non-slash token.
    PATH_PATTERNS = PATHS.map do |template|
      regex_src = template.split('/').map do |seg|
        seg.start_with?(':') ? '[a-zA-Z0-9._-]+' : Regexp.escape(seg)
      end.join('/')
      /\A#{regex_src}\z/
    end.freeze

    def self.valid_path?(path)
      PATH_PATTERNS.any? { |pattern| pattern.match?(path) }
    end

    def initialize(group, path, query_params: {})
      @group        = group
      @path         = path
      @query_params = query_params
    end

    # Required by ReactiveCaching to generate cache keys
    def id
      group.id
    end

    def calculate_reactive_cache
      return {} unless observability_setting

      tokens = Observability::O11yToken.generate_tokens(observability_setting)
      return {} unless tokens

      tokens.transform_keys { |key| key.to_s.underscore }
    rescue StandardError => e
      Gitlab::ErrorTracking.log_exception(e)
      {}
    end

    def title
      first_segment = @path.to_s.split('/').first.to_s
      SEGMENT_TITLES.fetch(first_segment, 'Observability')
    end

    def auth_tokens
      return {} unless observability_setting

      with_reactive_cache do |data|
        data
      end || {}
    end

    def url_with_path
      return unless observability_setting&.o11y_service_url

      ::URI.join(observability_setting.o11y_service_url, path)
    end

    def to_h
      {
        o11y_url: observability_setting&.o11y_service_url,
        path: path,
        auth_tokens: auth_tokens,
        title: title,
        query_params: @query_params
      }
    end

    def provisioning?
      auth_tokens&.dig('status') == :provisioning
    end

    private

    attr_reader :group, :path

    def observability_setting
      group.observability_group_o11y_setting
    end
    strong_memoize_attr :observability_setting
  end
end
