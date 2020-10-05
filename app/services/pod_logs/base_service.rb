# frozen_string_literal: true

module PodLogs
  class BaseService < ::BaseService
    include ReactiveCaching
    include Stepable

    attr_reader :cluster, :namespace, :params

    CACHE_KEY_GET_POD_LOG = 'get_pod_log'
    K8S_NAME_MAX_LENGTH = 253

    self.reactive_cache_work_type = :external_dependency

    def id
      cluster.id
    end

    def initialize(cluster, namespace, params: {})
      @cluster = cluster
      @namespace = namespace
      @params = filter_params(params.dup.stringify_keys).to_hash
    end

    def execute
      with_reactive_cache(
        CACHE_KEY_GET_POD_LOG,
        namespace,
        params
      ) do |result|
        result
      end
    end

    def calculate_reactive_cache(request, _namespace, _params)
      case request
      when CACHE_KEY_GET_POD_LOG
        execute_steps
      else
        exception = StandardError.new('Unknown reactive cache request')
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception, request: request)
        error(_('Unknown cache key'))
      end
    end

    private

    def valid_params
      %w(pod_name container_name)
    end

    def success_return_keys
      %i(status logs pod_name container_name pods)
    end

    def check_arguments(result)
      return error(_('Cluster does not exist')) if cluster.nil?
      return error(_('Namespace is empty')) if namespace.blank?

      result[:pod_name] = params['pod_name'].presence
      result[:container_name] = params['container_name'].presence

      return error(_('Invalid pod_name')) if result[:pod_name] && !result[:pod_name].is_a?(String)
      return error(_('Invalid container_name')) if result[:container_name] && !result[:container_name].is_a?(String)

      success(result)
    end

    def get_raw_pods(result)
      raise NotImplementedError
    end

    def get_pod_names(result)
      result[:pods] = result[:raw_pods].map { |p| p[:name] }

      success(result)
    end

    def pod_logs(result)
      raise NotImplementedError
    end

    def filter_return_keys(result)
      result.slice(*success_return_keys)
    end

    def filter_params(params)
      params.slice(*valid_params)
    end
  end
end
