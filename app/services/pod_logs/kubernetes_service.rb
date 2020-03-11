# frozen_string_literal: true

module PodLogs
  class KubernetesService < BaseService
    LOGS_LIMIT = 500.freeze
    REPLACEMENT_CHAR = "\u{FFFD}"

    EncodingHelperError = Class.new(StandardError)

    steps :check_arguments,
          :check_param_lengths,
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
          message: values[1]
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
