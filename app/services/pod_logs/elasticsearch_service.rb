# frozen_string_literal: true

module PodLogs
  class ElasticsearchService < BaseService
    steps :check_arguments,
          :check_param_lengths,
          :get_raw_pods,
          :get_pod_names,
          :check_pod_name,
          :check_container_name,
          :check_times,
          :check_search,
          :pod_logs,
          :filter_return_keys

    self.reactive_cache_worker_finder = ->(id, _cache_key, namespace, params) { new(::Clusters::Cluster.find(id), namespace, params: params) }

    private

    def valid_params
      %w(pod_name container_name search start end)
    end

    def check_times(result)
      result[:start] = params['start'] if params.key?('start') && Time.iso8601(params['start'])
      result[:end] = params['end'] if params.key?('end') && Time.iso8601(params['end'])

      success(result)
    rescue ArgumentError
      error(_('Invalid start or end time format'))
    end

    def check_search(result)
      result[:search] = params['search'] if params.key?('search')

      success(result)
    end

    def pod_logs(result)
      client = cluster&.application_elastic_stack&.elasticsearch_client
      return error(_('Unable to connect to Elasticsearch')) unless client

      result[:logs] = ::Gitlab::Elasticsearch::Logs.new(client).pod_logs(
        namespace,
        result[:pod_name],
        result[:container_name],
        result[:search],
        result[:start],
        result[:end]
      )

      success(result)
    rescue Elasticsearch::Transport::Transport::ServerError => e
      ::Gitlab::ErrorTracking.track_exception(e)

      error(_('Elasticsearch returned status code: %{status_code}') % {
        # ServerError is the parent class of exceptions named after HTTP status codes, eg: "Elasticsearch::Transport::Transport::Errors::NotFound"
        # there is no method on the exception other than the class name to determine the type of error encountered.
        status_code: e.class.name.split('::').last
      })
    end
  end
end
