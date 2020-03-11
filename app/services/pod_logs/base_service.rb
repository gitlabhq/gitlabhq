# frozen_string_literal: true

module PodLogs
  class BaseService < ::BaseService
    include ReactiveCaching
    include Stepable

    attr_reader :cluster, :namespace, :params

    CACHE_KEY_GET_POD_LOG = 'get_pod_log'
    K8S_NAME_MAX_LENGTH = 253

    SUCCESS_RETURN_KEYS = %i(status logs pod_name container_name pods).freeze

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

    def check_arguments(result)
      return error(_('Cluster does not exist')) if cluster.nil?
      return error(_('Namespace is empty')) if namespace.blank?

      success(result)
    end

    def check_param_lengths(_result)
      pod_name = params['pod_name'].presence
      container_name = params['container_name'].presence

      if pod_name&.length.to_i > K8S_NAME_MAX_LENGTH
        return error(_('pod_name cannot be larger than %{max_length}'\
          ' chars' % { max_length: K8S_NAME_MAX_LENGTH }))
      elsif container_name&.length.to_i > K8S_NAME_MAX_LENGTH
        return error(_('container_name cannot be larger than'\
          ' %{max_length} chars' % { max_length: K8S_NAME_MAX_LENGTH }))
      end

      success(pod_name: pod_name, container_name: container_name)
    end

    def get_raw_pods(result)
      result[:raw_pods] = cluster.kubeclient.get_pods(namespace: namespace)

      success(result)
    end

    def get_pod_names(result)
      result[:pods] = result[:raw_pods].map(&:metadata).map(&:name)

      success(result)
    end

    def check_pod_name(result)
      # If pod_name is not received as parameter, get the pod logs of the first
      # pod of this namespace.
      result[:pod_name] ||= result[:pods].first

      unless result[:pod_name]
        return error(_('No pods available'))
      end

      unless result[:pods].include?(result[:pod_name])
        return error(_('Pod does not exist'))
      end

      success(result)
    end

    def check_container_name(result)
      pod_details = result[:raw_pods].first { |p| p.metadata.name == result[:pod_name] }
      containers = pod_details.spec.containers.map(&:name)

      # select first container if not specified
      result[:container_name] ||= containers.first

      unless result[:container_name]
        return error(_('No containers available'))
      end

      unless containers.include?(result[:container_name])
        return error(_('Container does not exist'))
      end

      success(result)
    end

    def pod_logs(result)
      raise NotImplementedError
    end

    def filter_return_keys(result)
      result.slice(*SUCCESS_RETURN_KEYS)
    end

    def filter_params(params)
      params.slice(*valid_params)
    end
  end
end
