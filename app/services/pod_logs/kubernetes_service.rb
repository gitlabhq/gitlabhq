# frozen_string_literal: true

module PodLogs
  class KubernetesService < PodLogs::BaseService
    LOGS_LIMIT = 500
    REPLACEMENT_CHAR = "\u{FFFD}"

    EncodingHelperError = Class.new(StandardError)

    steps :check_arguments,
          :get_raw_pods,
          :get_pod_names,
          :check_pod_name,
          :check_container_name,
          :pod_logs,
          :encode_logs_to_utf8,
          :split_logs,
          :filter_return_keys

    self.reactive_cache_worker_finder = ->(id, _cache_key, namespace, params) { new(::Clusters::Cluster.find(id), namespace, params: params) }

    private

    def get_raw_pods(result)
      result[:raw_pods] = cluster.kubeclient.get_pods(namespace: namespace).map do |pod|
        {
          name: pod.metadata.name,
          container_names: pod.spec.containers.map(&:name)
        }
      end

      success(result)
    end

    def check_pod_name(result)
      # If pod_name is not received as parameter, get the pod logs of the first
      # pod of this namespace.
      result[:pod_name] ||= result[:pods].first

      unless result[:pod_name]
        return error(_('No pods available'))
      end

      unless result[:pod_name].length.to_i <= K8S_NAME_MAX_LENGTH
        return error(_('pod_name cannot be larger than %{max_length}'\
          ' chars' % { max_length: K8S_NAME_MAX_LENGTH }))
      end

      unless result[:pod_name] =~ Gitlab::Regex.kubernetes_dns_subdomain_regex
        return error(_('pod_name can contain only lowercase letters, digits, \'-\', and \'.\' and must start and end with an alphanumeric character'))
      end

      unless result[:pods].include?(result[:pod_name])
        return error(_('Pod does not exist'))
      end

      success(result)
    end

    def check_container_name(result)
      pod_details = result[:raw_pods].find { |p| p[:name] == result[:pod_name] }
      container_names = pod_details[:container_names]

      # select first container if not specified
      result[:container_name] ||= container_names.first

      unless result[:container_name]
        return error(_('No containers available'))
      end

      unless result[:container_name].length.to_i <= K8S_NAME_MAX_LENGTH
        return error(_('container_name cannot be larger than'\
          ' %{max_length} chars' % { max_length: K8S_NAME_MAX_LENGTH }))
      end

      unless result[:container_name] =~ Gitlab::Regex.kubernetes_dns_subdomain_regex
        return error(_('container_name can contain only lowercase letters, digits, \'-\', and \'.\' and must start and end with an alphanumeric character'))
      end

      unless container_names.include?(result[:container_name])
        return error(_('Container does not exist'))
      end

      success(result)
    end

    def pod_logs(result)
      result[:logs] = cluster.kubeclient.get_pod_log(
        result[:pod_name],
        namespace,
        container: result[:container_name],
        tail_lines: LOGS_LIMIT,
        timestamps: true
      ).body

      success(result)
    rescue Kubeclient::ResourceNotFoundError
      error(_('Pod not found'))
    rescue Kubeclient::HttpError => e
      ::Gitlab::ErrorTracking.track_exception(e)

      error(_('Kubernetes API returned status code: %{error_code}') % {
        error_code: e.error_code
      })
    end

    # Check https://gitlab.com/gitlab-org/gitlab/issues/34965#note_292261879
    # for more details on why this is necessary.
    def encode_logs_to_utf8(result)
      return success(result) if result[:logs].nil?
      return success(result) if result[:logs].encoding == Encoding::UTF_8

      result[:logs] = encode_utf8(result[:logs])

      success(result)
    rescue EncodingHelperError
      error(_('Unable to convert Kubernetes logs encoding to UTF-8'))
    end

    def split_logs(result)
      result[:logs] = result[:logs].strip.lines(chomp: true).map do |line|
        # message contains a RFC3339Nano timestamp, then a space, then the log line.
        # resolution of the nanoseconds can vary, so we split on the first space
        values = line.split(' ', 2)
        {
          timestamp: values[0],
          message: values[1],
          pod: result[:pod_name]
        }
      end

      success(result)
    end

    def encode_utf8(logs)
      utf8_logs = Gitlab::EncodingHelper.encode_utf8(logs.dup, replace: REPLACEMENT_CHAR)

      # Gitlab::EncodingHelper.encode_utf8 can return '' or nil if an exception
      # is raised while encoding. We prefer to return an error rather than wrongly
      # display blank logs.
      no_utf8_logs = logs.present? && utf8_logs.blank?
      unexpected_encoding = utf8_logs&.encoding != Encoding::UTF_8

      if no_utf8_logs || unexpected_encoding
        raise EncodingHelperError, 'Could not convert Kubernetes logs to UTF-8'
      end

      utf8_logs
    end
  end
end
