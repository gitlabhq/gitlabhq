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

  validate :deprecation_validation, unless: :template?
  validates :namespace,
    allow_blank: true,
    length: 1..63,
    if: :activated?,
    format: {
      with: Gitlab::Regex.kubernetes_namespace_regex,
      message: Gitlab::Regex.kubernetes_namespace_regex_message
    }

  after_save :clear_reactive_cache!

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

  def deprecated?
    !active
  end

  def deprecation_message
    content = _("Kubernetes service integration has been deprecated. %{deprecated_message_content} your Kubernetes clusters using the new <a href=\"%{url}\"/>Kubernetes Clusters</a> page") % {
      deprecated_message_content: deprecated_message_content,
      url: Gitlab::Routing.url_helpers.project_clusters_path(project)
    }
    content.html_safe
  end

  TEMPLATE_PLACEHOLDER = 'Kubernetes namespace'.freeze

  private

  def enforce_namespace_to_lower_case
    self.namespace = self.namespace&.downcase
  end

  def deprecation_validation
    return if active_changed?(from: true, to: false)

    if deprecated?
      errors[:base] << deprecation_message
    end
  end

  def deprecated_message_content
    if active?
      _("Your Kubernetes cluster information on this page is still editable, but you are advised to disable and reconfigure")
    else
      _("Fields on this page are now uneditable, you can configure")
    end
  end
end
