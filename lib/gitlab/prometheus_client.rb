# frozen_string_literal: true

module Gitlab
  # Helper methods to interact with Prometheus network services & resources
  class PrometheusClient
    Error = Class.new(StandardError)
    QueryError = Class.new(Gitlab::PrometheusClient::Error)

    # Target number of data points for `query_range`.
    # Please don't exceed the limit of 11000 data points
    # See https://github.com/prometheus/prometheus/blob/91306bdf24f5395e2601773316945a478b4b263d/web/api/v1/api.go#L347
    QUERY_RANGE_DATA_POINTS = 600

    # Minimal value of the `step` parameter for `query_range` in seconds.
    QUERY_RANGE_MIN_STEP = 60

    attr_reader :rest_client, :headers

    def initialize(rest_client)
      @rest_client = rest_client
    end

    def ping
      json_api_get('query', query: '1')
    end

    def proxy(type, args)
      path = api_path(type)
      get(path, args)
    rescue RestClient::ExceptionWithResponse => ex
      if ex.response
        ex.response
      else
        raise PrometheusClient::Error, "Network connection error"
      end
    rescue RestClient::Exception
      raise PrometheusClient::Error, "Network connection error"
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
      ['api', 'v1', type].join('/')
    end

    def json_api_get(type, args = {})
      path = api_path(type)
      response = get(path, args)
      handle_response(response)
    rescue RestClient::ExceptionWithResponse => ex
      if ex.response
        handle_exception_response(ex.response)
      else
        raise PrometheusClient::Error, "Network connection error"
      end
    rescue RestClient::Exception
      raise PrometheusClient::Error, "Network connection error"
    end

    def get(path, args)
      rest_client[path].get(params: args)
    rescue SocketError
      raise PrometheusClient::Error, "Can't connect to #{rest_client.url}"
    rescue OpenSSL::SSL::SSLError
      raise PrometheusClient::Error, "#{rest_client.url} contains invalid SSL data"
    rescue Errno::ECONNREFUSED
      raise PrometheusClient::Error, 'Connection refused'
    end

    def handle_response(response)
      json_data = parse_json(response.body)
      if response.code == 200 && json_data['status'] == 'success'
        json_data['data'] || {}
      else
        raise PrometheusClient::Error, "#{response.code} - #{response.body}"
      end
    end

    def handle_exception_response(response)
      if response.code == 200 && response['status'] == 'success'
        response['data'] || {}
      elsif response.code == 400
        json_data = parse_json(response.body)
        raise PrometheusClient::QueryError, json_data['error'] || 'Bad data received'
      else
        raise PrometheusClient::Error, "#{response.code} - #{response.body}"
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
