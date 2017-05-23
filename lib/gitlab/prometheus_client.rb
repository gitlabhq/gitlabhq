module Gitlab
  PrometheusError = Class.new(StandardError)

  # Helper methods to interact with Prometheus network services & resources
  class PrometheusClient
    attr_reader :api_url, :rest_client, :headers

    def initialize(api_url:, rest_client: nil, headers: nil)
      @api_url = api_url
      @rest_client = rest_client || RestClient::Resource.new(api_url)
      @headers = headers || {}
    end

    def ping
      json_api_get('query', query: '1')
    end

    def query(query, time: Time.now)
      get_result('vector') do
        json_api_get('query', query: query, time: time.to_f)
      end
    end

    def query_range(query, start: 8.hours.ago, stop: Time.now)
      get_result('matrix') do
        json_api_get('query_range',
          query: query,
          start: start.to_f,
          end: stop.to_f,
          step: 1.minute.to_i)
      end
    end

    private

    def json_api_get(type, args = {})
      path = ['api', 'v1', type].join('/')
      get(path, args)
    rescue Errno::ECONNREFUSED
      raise PrometheusError, 'Connection refused'
    end

    def get(path, args)
      response = rest_client[path].get(headers.merge(params: args))
      handle_response(response)
    rescue SocketError
      raise PrometheusError, "Can't connect to #{url}"
    rescue OpenSSL::SSL::SSLError
      raise PrometheusError, "#{url} contains invalid SSL data"
    rescue HTTParty::Error
      raise PrometheusError, "Network connection error"
    end

    def handle_response(response)
      json_data = json_response(response)
      if response.code == 200 && json_data['status'] == 'success'
        json_data['data'] || {}
      elsif response.code == 400
        raise PrometheusError, json_data['error'] || 'Bad data received'
      else
        raise PrometheusError, "#{response.code} - #{response.body}"
      end
    end

    def json_response(response)
      JSON.parse(response.body)
    end

    def get_result(expected_type)
      data = yield
      data['result'] if data['resultType'] == expected_type
    end
  end
end
