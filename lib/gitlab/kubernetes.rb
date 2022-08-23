# frozen_string_literal: true

module Gitlab
  # Helper methods to do with Kubernetes network services & resources
  module Kubernetes
    def self.build_header_hash
      Hash.new { |h, k| h[k] = [] }
    end

    # This is the comand that is run to start a terminal session. Kubernetes
    # expects `command=foo&command=bar, not `command[]=foo&command[]=bar`
    EXEC_COMMAND = URI.encode_www_form(
      ['sh', '-c', 'bash || sh'].map { |value| ['command', value] }
    )

    # Filters an array of pods (as returned by the kubernetes API) by their labels
    def filter_by_label(items, labels = {})
      items.select do |item|
        metadata = item.fetch("metadata", {})
        item_labels = metadata.fetch("labels", nil)
        next unless item_labels

        labels.all? { |k, v| item_labels[k.to_s] == v }
      end
    end

    # Filters an array of pods (as returned by the kubernetes API) by their annotations
    def filter_by_annotation(items, annotations = {})
      items.select do |item|
        metadata = item.fetch("metadata", {})
        item_annotations = metadata.fetch("annotations", nil)
        next unless item_annotations

        annotations.all? { |k, v| item_annotations[k.to_s] == v }
      end
    end

    # Filters an array of pods (as returned by the kubernetes API) by their project and environment
    def filter_by_project_environment(items, app, env)
      filter_by_annotation(items, {
        'app.gitlab.com/app' => app,
        'app.gitlab.com/env' => env
      })
    end

    def filter_by_legacy_label(items, app, env)
      legacy_items = filter_by_label(items, { app: env })

      non_legacy_items = filter_by_project_environment(legacy_items, app, env)

      legacy_items - non_legacy_items
    end

    # Converts a pod (as returned by the kubernetes API) into a terminal
    def terminals_for_pod(api_url, namespace, pod)
      metadata = pod.fetch("metadata", {})
      status   = pod.fetch("status", {})
      spec     = pod.fetch("spec", {})

      containers = spec["containers"]
      pod_name   = metadata["name"]
      phase      = status["phase"]

      return unless containers.present? && pod_name.present? && phase == "Running"

      created_at = begin
        DateTime.parse(metadata["creationTimestamp"])
      rescue StandardError
        nil
      end

      containers.map do |container|
        {
          selectors: { pod: pod_name, container: container["name"] },
          url: container_exec_url(api_url, namespace, pod_name, container["name"]),
          subprotocols: ['channel.k8s.io'],
          headers: ::Gitlab::Kubernetes.build_header_hash,
          created_at: created_at
        }
      end
    end

    def add_terminal_auth(terminal, token:, max_session_time:, ca_pem: nil)
      terminal[:headers] ||= ::Gitlab::Kubernetes.build_header_hash
      terminal[:headers]['Authorization'] << "Bearer #{token}"
      terminal[:max_session_time] = max_session_time
      terminal[:ca_pem] = ca_pem if ca_pem.present?
    end

    def container_exec_url(api_url, namespace, pod_name, container_name)
      url = URI.parse(api_url)
      url.path = [
        url.path.sub(%r{/+\z}, ''),
        'api', 'v1',
        'namespaces', ERB::Util.url_encode(namespace),
        'pods', ERB::Util.url_encode(pod_name),
        'exec'
      ].join('/')

      url.query = {
        container: container_name,
        tty: true,
        stdin: true,
        stdout: true,
        stderr: true
      }.to_query + '&' + EXEC_COMMAND

      case url.scheme
      when 'http'
        url.scheme = 'ws'
      when 'https'
        url.scheme = 'wss'
      end

      url.to_s
    end

    def to_kubeconfig(url:, namespace:, token:, ca_pem: nil)
      return unless token.present?

      config = {
        apiVersion: 'v1',
        clusters: [
          name: 'gitlab-deploy',
          cluster: {
            server: url
          }
        ],
        contexts: [
          name: 'gitlab-deploy',
          context: {
            cluster: 'gitlab-deploy',
            namespace: namespace,
            user: 'gitlab-deploy'
          }
        ],
        'current-context': 'gitlab-deploy',
        kind: 'Config',
        users: [
          {
            name: 'gitlab-deploy',
            user: { token: token }
          }
        ]
      }

      kubeconfig_embed_ca_pem(config, ca_pem) if ca_pem

      YAML.dump(config.deep_stringify_keys)
    end

    private

    def kubeconfig_embed_ca_pem(config, ca_pem)
      cluster = config.dig(:clusters, 0, :cluster)
      cluster[:'certificate-authority-data'] = Base64.strict_encode64(ca_pem)
    end
  end
end
