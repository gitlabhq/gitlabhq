# frozen_string_literal: true

module Gitlab
  # Helper methods to interact with Prometheus network services & resources
  class PrometheusClient
    include Gitlab::Utils::StrongMemoize
    Error = Class.new(StandardError)
    QueryError = Class.new(Gitlab::PrometheusClient::Error)

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

    def proxy(type, args)
      path = api_path(type)
      get(path, args)
    rescue Gitlab::HTTP::ResponseError => ex
      raise PrometheusClient::Error, "Network connection error" unless ex.response && ex.response.try(:code)

      handle_response(ex.response)
    end

    def query(query, time: Time.now)
      get_result('vector') do
        json_api_get('query', query: query, time: time.to_f)
      end
    end

    def query_range(query, start: 8.hours.ago, stop: Time.now)
      start = start.to_f
      stop = stop.to_f
      step = self.class.compute_step(start, stop)

      get_result('matrix') do
        json_api_get(
          'query_range',
          query: query,
          start: start,
          end: stop,
          step: step
        )
      end
    end

    def label_values(name = '__name__')
      json_api_get("label/#{name}/values")
    end

    def series(*matches, start: 8.hours.ago, stop: Time.now)
      json_api_get('series', 'match': matches, start: start.to_f, end: stop.to_f)
    end

    def self.compute_step(start, stop)
      diff = stop - start

      step = (diff / QUERY_RANGE_DATA_POINTS).ceil

      [QUERY_RANGE_MIN_STEP, step].max
    end

    private

    def api_path(type)
      [api_url, 'api', 'v1', type].join('/')
    end

    def json_api_get(type, args = {})
      path = api_path(type)
      response = get(path, args)
      handle_response(response)
    rescue Gitlab::HTTP::ResponseError => ex
      raise PrometheusClient::Error, "Network connection error" unless ex.response && ex.response.try(:code)

      handle_response(ex.response)
    end

    def gitlab_http_key(key)
      RESTCLIENT_GITLAB_HTTP_KEYMAP[key] || key
    end

    def mapped_options
      options.keys.map { |k| [gitlab_http_key(k), options[k]] }.to_h
    end

    def http_options
      strong_memoize(:http_options) do
        { follow_redirects: false }.merge(mapped_options)
      end
    end

    def get(path, args)
      Gitlab::HTTP.get(path, { query: args }.merge(http_options) )
    rescue SocketError
      raise PrometheusClient::Error, "Can't connect to #{api_url}"
    rescue OpenSSL::SSL::SSLError
      raise PrometheusClient::Error, "#{api_url} contains invalid SSL data"
    rescue Errno::ECONNREFUSED
      raise PrometheusClient::Error, 'Connection refused'
    end

    def handle_response(response)
      response_code = response.try(:code)
      response_body = response.try(:body)

      raise PrometheusClient::Error, "#{response_code} - #{response_body}" unless response_code

      json_data = parse_json(response_body) if [200, 400].include?(response_code)

      case response_code
      when 200
        json_data['data'] if response['status'] == 'success'
      when 400
        raise PrometheusClient::QueryError, json_data['error'] || 'Bad data received'
      else
        raise PrometheusClient::Error, "#{response_code} - #{response_body}"
      end
    end

    def get_result(expected_type)
      data = yield
      data['result'] if data['resultType'] == expected_type
    end

    def parse_json(response_body)
      JSON.parse(response_body)
    rescue JSON::ParserError
      raise PrometheusClient::Error, 'Parsing response failed'
    end
  end
end
