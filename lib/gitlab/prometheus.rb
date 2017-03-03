module Gitlab
  class PrometheusError < StandardError; end

  # Helper methods to interact with Prometheus network services & resources
  module Prometheus
    def ping
      json_api_get("query", query: "1")
    end

    def query(query, time = Time.now)
      response = json_api_get("query",
        query: query,
        time: time.utc.to_f)

      data = response.fetch('data', {})

      if data['resultType'].to_s == 'vector'
        data['result']
      end
    end

    def query_range(query, start_time, end_time = Time.now, step = 1.minute)
      response = json_api_get("query_range",
        query: query,
        start: start_time.utc.to_f,
        end: end_time.utc.to_f,
        step: step.to_i)

      data = response.fetch('data', {})

      if data['resultType'].to_s == 'matrix'
        data['result']
      end
    end

    private

    def json_api_get(type, args = {})
      url = join_api_url(type, args)
      return PrometheusError.new("invalid URL") unless url

      api_parse_response HTTParty.get(url)
    rescue Errno::ECONNREFUSED
      raise PrometheusError.new("connection refused")
    end

    def api_parse_response(response)
      if response.code == 200 && response['status'] == 'success'
        response
      elsif response.code == 400
        raise PrometheusError.new(response['error'] || 'bad data received')
      else
        raise PrometheusError.new("#{response.code} #{response.message}")
      end
    end

    def join_api_url(type, args = {})
      url = URI.parse(api_url)
      url.path = [
        url.path.sub(%r{/+\z}, ''),
        'api', 'v1',
        ERB::Util.url_encode(type)
      ].join('/')

      url.query = args.to_query
      url.to_s
    end
  end
end
