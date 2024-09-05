# frozen_string_literal: true

module Gitlab
  # Helper methods to interact with Prometheus network services & resources
  class PrometheusClient
    include Gitlab::Utils::StrongMemoize

    Error = Class.new(StandardError)
    ConnectionError = Class.new(Gitlab::PrometheusClient::Error)
    UnexpectedResponseError = Class.new(Gitlab::PrometheusClient::Error)
    QueryError = Class.new(Gitlab::PrometheusClient::Error)
    HEALTHY_RESPONSE = "Prometheus is Healthy.\n"

    # Target number of data points for `query_range`.
    # Please don't exceed the limit of 11000 data points
    # See https://github.com/prometheus/prometheus/blob/91306bdf24f5395e2601773316945a478b4b263d/web/api/v1/api.go#L347
    QUERY_RANGE_DATA_POINTS = 600

    # Minimal value of the `step` parameter for `query_range` in seconds.
    QUERY_RANGE_MIN_STEP = 60

    # Key translation between RestClient and Gitlab::HTTP (HTTParty)
    RESTCLIENT_GITLAB_HTTP_KEYMAP = {
      ssl_cert_store: :cert_store
    }.freeze

    attr_reader :api_url, :options
    private :api_url, :options

    def initialize(api_url, options = {})
      @api_url = api_url.chomp('/')
      @options = options
    end

    def ping
      json_api_get('query', query: '1')
    end

    def healthy?
      response_body = handle_management_api_response(get(health_url, {}))

      # From Prometheus docs: This endpoint always returns 200 and should be used to check Prometheus health.
      response_body == HEALTHY_RESPONSE
    end

    def ready?
      response = get(ready_url, {})

      # From Prometheus docs: This endpoint returns 200 when Prometheus is ready to serve traffic (i.e. respond to queries).
      response.code == 200
    rescue StandardError => e
      raise PrometheusClient::UnexpectedResponseError, e.message.to_s
    end

    def proxy(type, args)
      path = api_path(type)
      get(path, args)
    rescue Gitlab::HTTP::ResponseError => ex
      raise PrometheusClient::ConnectionError, "Network connection error" unless ex.response && ex.response.try(:code)

      handle_querying_api_response(ex.response)
    end

    def query(query, time: Time.now)
      get_result('vector') do
        json_api_get('query', query: query, time: time.to_f)
      end
    end

    def query_range(query, start_time: 8.hours.ago, end_time: Time.now)
      start_time = start_time.to_f
      end_time = end_time.to_f
      step = self.class.compute_step(start_time, end_time)

      get_result('matrix') do
        json_api_get(
          'query_range',
          query: query,
          start: start_time,
          end: end_time,
          step: step
        )
      end
    end

    # Queries Prometheus with the given aggregate query and groups the results by mapping
    # metric labels to their respective values.
    #
    # @return [Hash] mapping labels to their aggregate numeric values, or the empty hash if no results were found
    def aggregate(aggregate_query, time: Time.now, transform_value: :to_f)
      response = query(aggregate_query, time: time)
      response.to_h do |result|
        key = block_given? ? yield(result['metric']) : result['metric']
        _timestamp, value = result['value']
        [key, value.public_send(transform_value)] # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def label_values(name = '__name__')
      json_api_get("label/#{name}/values")
    end

    def series(*matches, start_time: 8.hours.ago, end_time: Time.now)
      json_api_get('series', match: matches, start: start_time.to_f, end: end_time.to_f)
    end

    def self.compute_step(start_time, end_time)
      diff = end_time - start_time

      step = (diff / QUERY_RANGE_DATA_POINTS).ceil

      [QUERY_RANGE_MIN_STEP, step].max
    end

    def health_url
      "#{api_url}/-/healthy"
    end

    def ready_url
      "#{api_url}/-/ready"
    end

    private

    def api_path(type)
      [api_url, 'api', 'v1', type].join('/')
    end

    def json_api_get(type, args = {})
      path = api_path(type)
      response = get(path, args)
      handle_querying_api_response(response)
    rescue Gitlab::HTTP::ResponseError => ex
      raise PrometheusClient::ConnectionError, "Network connection error" unless ex.response && ex.response.try(:code)

      handle_querying_api_response(ex.response)
    end

    def gitlab_http_key(key)
      RESTCLIENT_GITLAB_HTTP_KEYMAP[key] || key
    end

    def mapped_options
      options.keys.to_h { |k| [gitlab_http_key(k), options[k]] }
    end

    def http_options
      strong_memoize(:http_options) do
        { follow_redirects: false }.merge(mapped_options)
      end
    end

    def get(path, args)
      Gitlab::HTTP.get(path, { query: args }.merge(http_options))
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      raise PrometheusClient::ConnectionError, e.message
    end

    def handle_management_api_response(response)
      if response.code == 200
        response.body
      else
        raise PrometheusClient::UnexpectedResponseError, "#{response.code} - #{response.body}"
      end
    end

    def handle_querying_api_response(response)
      response_code = response.try(:code)
      response_body = response.try(:body)

      raise PrometheusClient::UnexpectedResponseError, "#{response_code} - #{response_body}" unless response_code

      json_data = parse_json(response_body) if [200, 400].include?(response_code)

      case response_code
      when 200
        json_data['data'] if response['status'] == 'success'
      when 400
        raise PrometheusClient::QueryError, json_data['error'] || 'Bad data received'
      else
        raise PrometheusClient::UnexpectedResponseError, "#{response_code} - #{response_body}"
      end
    end

    def get_result(expected_type)
      data = yield
      data['result'] if data['resultType'] == expected_type
    end

    def parse_json(response_body)
      Gitlab::Json.parse(response_body, legacy_mode: true)
    rescue JSON::ParserError
      raise PrometheusClient::UnexpectedResponseError, 'Parsing response failed'
    end
  end
end
