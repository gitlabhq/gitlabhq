module Gitlab
  PrometheusError = Class.new(StandardError)

  # Helper methods to interact with Prometheus network services & resources
  class PrometheusClient
    attr_reader :api_url

    def initialize(api_url:)
      @api_url = api_url
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

    def label_values(name='__name__')
      json_api_get("label/#{name}/values")
    end

    def series(*matches, start: 8.hours.ago, stop: Time.now)
      json_api_get('series', 'match': matches, start: start.to_f, end: stop.to_f)
    end

    private

    def json_api_get(type, args = {})
      get(join_api_url(type, args))
    rescue Errno::ECONNREFUSED
      raise PrometheusError, 'Connection refused'
    end

    def join_api_url(type, args = {})
      url = URI.parse(api_url)
    rescue URI::Error
      raise PrometheusError, "Invalid API URL: #{api_url}"
    else
      url.path = [url.path.sub(%r{/+\z}, ''), 'api', 'v1', type].join('/')
      url.query = args.to_query

      url.to_s
    end

    def get(url)
      handle_response(HTTParty.get(url))
    rescue SocketError
      raise PrometheusError, "Can't connect to #{url}"
    rescue OpenSSL::SSL::SSLError
      raise PrometheusError, "#{url} contains invalid SSL data"
    rescue HTTParty::Error
      raise PrometheusError, "Network connection error"
    end

    def handle_response(response)
      if response.code == 200 && response['status'] == 'success'
        response['data'] || {}
      elsif response.code == 400
        raise PrometheusError, response['error'] || 'Bad data received'
      else
        raise PrometheusError, "#{response.code} - #{response.body}"
      end
    end

    def get_result(expected_type)
      data = yield
      data['result'] if data['resultType'] == expected_type
    end
  end
end
