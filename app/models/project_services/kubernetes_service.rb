# frozen_string_literal: true

class KubernetesService < Service
  default_value_for :category, 'deployment'

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

  def deprecation_validation
    return if active_changed?(from: true, to: false) || (new_record? && !active?)

    if deprecated?
      errors[:base] << deprecation_message
    end
  end
end
