##
# KubernetesService is shallow parameters holder
# On first create in context of project it creates Cluster::Cluster
# with all parameters
class KubernetesService < DeploymentService
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
    validates :api_url, url: true
    validates :token
  end

  before_validation :enforce_namespace_to_lower_case

  validates :namespace,
    allow_blank: true,
    length: 1..63,
    if: :activated?,
    format: {
      with: Gitlab::Regex.kubernetes_namespace_regex,
      message: Gitlab::Regex.kubernetes_namespace_regex_message
    }

  after_create :create_project_kubernetes_cluster, unless: :template?

  def initialize_properties
    self.properties = {} if properties.nil?
  end

  def title
    'Kubernetes'
  end

  def description
    'Kubernetes / Openshift integration'
  end

  def help
    'To enable terminal access to Kubernetes environments, label your ' \
    'deployments with `app=$CI_ENVIRONMENT_SLUG`'
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

  def actual_namespace
    if namespace.present?
      namespace
    else
      default_namespace
    end
  end

  # Check we can connect to the Kubernetes API
  def test(*args)
    kubeclient = build_kubeclient!

    kubeclient.discover
    { success: kubeclient.discovered, result: "Checked API discovery endpoint" }
  rescue => err
    { success: false, result: err }
  end

  TEMPLATE_PLACEHOLDER = 'Kubernetes namespace'.freeze

  private

  def create_project_kubernetes_cluster
    return unless active?

    ::Clusters::Cluster.create(cluster_attributes_from_service_template)
  end

  def cluster_attributes_from_service_template
    {
      name: 'kubernetes-template',
      projects: [project],
      provider_type: :user,
      platform_type: :kubernetes,
      platform_kubernetes_attributes: platform_kubernetes_attributes_from_service_template
    }
  end

  def platform_kubernetes_attributes_from_service_template
    {
      api_url: api_url,
      ca_pem: ca_pem,
      token: token,
      namespace: namespace
    }
  end

  def namespace_placeholder
    default_namespace || TEMPLATE_PLACEHOLDER
  end

  def default_namespace
    return unless project

    slug = "#{project.path}-#{project.id}".downcase
    slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
  end

  def enforce_namespace_to_lower_case
    self.namespace = self.namespace&.downcase
  end
end
