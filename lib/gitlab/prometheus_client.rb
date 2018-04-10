module Gitlab
  # Helper methods to interact with Prometheus network services & resources
  class PrometheusClient
    Error = Class.new(StandardError)
    QueryError = Class.new(Gitlab::PrometheusClient::Error)

    attr_reader :rest_client, :headers

    def initialize(rest_client)
      @rest_client = rest_client
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

    def label_values(name = '__name__')
      json_api_get("label/#{name}/values")
    end

    def series(*matches, start: 8.hours.ago, stop: Time.now)
      json_api_get('series', 'match': matches, start: start.to_f, end: stop.to_f)
    end

    private

    def json_api_get(type, args = {})
      path = ['api', 'v1', type].join('/')
      get(path, args)
    rescue JSON::ParserError
      raise PrometheusClient::Error, 'Parsing response failed'
    rescue Errno::ECONNREFUSED
      raise PrometheusClient::Error, 'Connection refused'
    end

    def get(path, args)
      response = rest_client[path].get(params: args)
      handle_response(response)
    rescue SocketError
      raise PrometheusClient::Error, "Can't connect to #{rest_client.url}"
    rescue OpenSSL::SSL::SSLError
      raise PrometheusClient::Error, "#{rest_client.url} contains invalid SSL data"
    rescue RestClient::ExceptionWithResponse => ex
      if ex.response
        handle_exception_response(ex.response)
      else
        raise PrometheusClient::Error, "Network connection error"
      end
    rescue RestClient::Exception
      raise PrometheusClient::Error, "Network connection error"
    end

    def handle_response(response)
      json_data = JSON.parse(response.body)
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
        json_data = JSON.parse(response.body)
        raise PrometheusClient::QueryError, json_data['error'] || 'Bad data received'
      else
        raise PrometheusClient::Error, "#{response.code} - #{response.body}"
      end
    end

    def get_result(expected_type)
      data = yield
      data['result'] if data['resultType'] == expected_type
    end
  end
end
