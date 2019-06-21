# frozen_string_literal: true

##
# NOTE:
# We'll move this class to Clusters::Platforms::Kubernetes, which contains exactly the same logic.
# After we've migrated data, we'll remove KubernetesService. This would happen in a few months.
# If you're modyfiyng this class, please note that you should update the same change in Clusters::Platforms::Kubernetes.
class KubernetesService < Service
  include Gitlab::Kubernetes
  include ReactiveCaching

  default_value_for :category, 'deployment'

  self.reactive_cache_key = ->(service) { [service.class.model_name.singular, service.project_id] }

  # Namespace defaults to the project path, but can be overridden in case that
  # is an invalid or inappropriate name
  prop_accessor :namespace

  #  Access to kubernetes is directly through the API
  prop_accessor :api_url

  # Bearer authentication
  # TODO:  user/password auth, client certificates
  prop_accessor :token

  # Provide a custom CA bundle for self-signed deployments
  prop_accessor :ca_pem

  with_options presence: true, if: :activated? do
    validates :api_url, public_url: true
    validates :token
  end

  before_validation :enforce_namespace_to_lower_case

  attr_accessor :skip_deprecation_validation

  validate :deprecation_validation, unless: :skip_deprecation_validation

  validates :namespace,
    allow_blank: true,
    length: 1..63,
    if: :activated?,
    format: {
      with: Gitlab::Regex.kubernetes_namespace_regex,
      message: Gitlab::Regex.kubernetes_namespace_regex_message
    }

  after_save :clear_reactive_cache!

  def self.supported_events
    %w()
  end

  def can_test?
    false
  end

  def initialize_properties
    self.properties = {} if properties.nil?
  end

  def title
    'Kubernetes'
  end

  def description
    'Kubernetes / OpenShift integration'
  end

  def self.to_param
    'kubernetes'
  end

  def fields
    [
        { type: 'text',
          name: 'api_url',
          title: 'API URL',
          placeholder: 'Kubernetes API URL, like https://kube.example.com/' },
        { type: 'textarea',
          name: 'ca_pem',
          title: 'CA Certificate',
          placeholder: 'Certificate Authority bundle (PEM format)' },
        { type: 'text',
          name: 'namespace',
          title: 'Project namespace (optional/unique)',
          placeholder: namespace_placeholder },
        { type: 'text',
          name: 'token',
          title: 'Token',
          placeholder: 'Service token' }
    ]
  end

  def kubernetes_namespace_for(project)
    if namespace.present?
      namespace
    else
      default_namespace
    end
  end

  # Check we can connect to the Kubernetes API
  def test(*args)
    kubeclient = build_kube_client!

    kubeclient.core_client.discover
    { success: kubeclient.core_client.discovered, result: "Checked API discovery endpoint" }
  rescue => err
    { success: false, result: err }
  end

  # Project param was added on
  # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22011,
  # as a way to keep this service compatible with
  # Clusters::Platforms::Kubernetes, it won't be used on this method
  # as it's only needed for Clusters::Cluster.
  def predefined_variables(project:)
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables
        .append(key: 'KUBE_URL', value: api_url)
        .append(key: 'KUBE_TOKEN', value: token, public: false, masked: true)
        .append(key: 'KUBE_NAMESPACE', value: kubernetes_namespace_for(project))
        .append(key: 'KUBECONFIG', value: kubeconfig, public: false, file: true)

      if ca_pem.present?
        variables
          .append(key: 'KUBE_CA_PEM', value: ca_pem)
          .append(key: 'KUBE_CA_PEM_FILE', value: ca_pem, file: true)
      end
    end
  end

  # Constructs a list of terminals from the reactive cache
  #
  # Returns nil if the cache is empty, in which case you should try again a
  # short time later
  def terminals(environment)
    with_reactive_cache do |data|
      project = environment.project

      pods = filter_by_project_environment(data[:pods], project.full_path_slug, environment.slug)
      terminals = pods.flat_map { |pod| terminals_for_pod(api_url, kubernetes_namespace_for(project), pod) }.compact
      terminals.each { |terminal| add_terminal_auth(terminal, terminal_auth) }
    end
  end

  # Caches resources in the namespace so other calls don't need to block on
  # network access
  def calculate_reactive_cache
    return unless active? && project && !project.pending_delete?

    # We may want to cache extra things in the future
    { pods: read_pods }
  end

  def kubeclient
    @kubeclient ||= build_kube_client!
  end

  def deprecated?
    true
  end

  def editable?
    false
  end

  def deprecation_message
    content = if project
                _("Kubernetes service integration has been disabled. Fields on this page are not used by GitLab, you can configure your Kubernetes clusters using the new <a href=\"%{url}\"/>Kubernetes Clusters</a> page") % {
                  url: Gitlab::Routing.url_helpers.project_clusters_path(project)
                }
              else
                _("The instance-level Kubernetes service integration is disabled. Your data has been migrated to an <a href=\"%{url}\"/>instance-level cluster</a>.") % {
                  url: Gitlab::Routing.url_helpers.admin_clusters_path
                }
              end

    content.html_safe
  end

  TEMPLATE_PLACEHOLDER = 'Kubernetes namespace'.freeze

  private

  def kubeconfig
    to_kubeconfig(
      url: api_url,
      namespace: kubernetes_namespace_for(project),
      token: token,
      ca_pem: ca_pem)
  end

  def namespace_placeholder
    default_namespace || TEMPLATE_PLACEHOLDER
  end

  def default_namespace
    return unless project

    slug = "#{project.path}-#{project.id}".downcase
    slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
  end

  def build_kube_client!
    raise "Incomplete settings" unless api_url && kubernetes_namespace_for(project) && token

    Gitlab::Kubernetes::KubeClient.new(
      api_url,
      auth_options: kubeclient_auth_options,
      ssl_options: kubeclient_ssl_options,
      http_proxy_uri: ENV['http_proxy']
    )
  end

  # Returns a hash of all pods in the namespace
  def read_pods
    kubeclient = build_kube_client!

    kubeclient.get_pods(namespace: kubernetes_namespace_for(project)).as_json
  rescue Kubeclient::ResourceNotFoundError
    []
  end

  def kubeclient_ssl_options
    opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

    if ca_pem.present?
      opts[:cert_store] = OpenSSL::X509::Store.new
      opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
    end

    opts
  end

  def kubeclient_auth_options
    { bearer_token: token }
  end

  def terminal_auth
    {
      token: token,
      ca_pem: ca_pem,
      max_session_time: Gitlab::CurrentSettings.terminal_max_session_time
    }
  end

  def enforce_namespace_to_lower_case
    self.namespace = self.namespace&.downcase
  end

  def deprecation_validation
    return if active_changed?(from: true, to: false) || (new_record? && !active?)

    if deprecated?
      errors[:base] << deprecation_message
    end
  end
end
