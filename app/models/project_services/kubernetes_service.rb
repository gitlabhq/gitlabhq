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

    validates :namespace,
      format: {
        with: Gitlab::Regex.kubernetes_namespace_regex,
        message: Gitlab::Regex.kubernetes_namespace_regex_message,
      },
      length: 1..63
  end

  def initialize_properties
    if properties.nil?
      self.properties = {}
      self.namespace = project.path if project.present?
    end
  end

  def title
    'Kubernetes'
  end

  def description
    'Kubernetes / Openshift integration'
  end

  def help
    ''
  end

  def to_param
    'kubernetes'
  end

  def fields
    [
        { type: 'text',
          name: 'namespace',
          title: 'Kubernetes namespace',
          placeholder: 'Kubernetes namespace',
        },
        { type: 'text',
          name: 'api_url',
          title: 'API URL',
          placeholder: 'Kubernetes API URL, like https://kube.example.com/',
        },
        { type: 'text',
          name: 'token',
          title: 'Service token',
          placeholder: 'Service token',
        },
        { type: 'textarea',
          name: 'ca_pem',
          title: 'Custom CA bundle',
          placeholder: 'Certificate Authority bundle (PEM format)',
        },
    ]
  end

  # Check we can connect to the Kubernetes API
  def test(*args)
    kubeclient = build_kubeclient
    kubeclient.discover

    { success: kubeclient.discovered, result: "Checked API discovery endpoint" }
  rescue => err
    { success: false, result: err }
  end

  def predefined_variables
    variables = [
      { key: 'KUBE_URL', value: api_url, public: true },
      { key: 'KUBE_TOKEN', value: token, public: false },
      { key: 'KUBE_NAMESPACE', value: namespace, public: true }
    ]
    variables << { key: 'KUBE_CA_PEM', value: ca_pem, public: true } if ca_pem.present?
    variables
  end

  private

  def build_kubeclient(api_path = '/api', api_version = 'v1')
    return nil unless api_url && namespace && token

    url = URI.parse(api_url)
    url.path = url.path[0..-2] if url.path[-1] == "/"
    url.path += api_path

    ::Kubeclient::Client.new(
      url,
      api_version,
      ssl_options: kubeclient_ssl_options,
      auth_options: kubeclient_auth_options,
      http_proxy_uri: ENV['http_proxy']
    )
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
end
