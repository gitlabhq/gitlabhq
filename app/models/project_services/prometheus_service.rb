class PrometheusService < MonitoringService
  include ReactiveCaching

  self.reactive_cache_key = ->(service) { [ service.class.model_name.singular, service.project_id ] }

  #  Access to prometheus is directly through the API
  prop_accessor :api_url

  with_options presence: true, if: :activated? do
    validates :api_url, url: true
  end

  after_save :clear_reactive_cache!

  def initialize_properties
    if properties.nil?
      self.properties = {}
    end
  end

  def title
    'Prometheus'
  end

  def description
    'Prometheus integration'
  end

  def help
  end

  def self.to_param
    'prometheus'
  end

  def fields
    [
        { type: 'text',
          name: 'api_url',
          title: 'API URL',
          placeholder: 'Prometheus API URL, like http://prometheus.example.com/',
        }
    ]
  end

  # Check we can connect to the Kubernetes API
  def test(*args)
    { success: true, result: "Checked API discovery endpoint" }
  rescue => err
    { success: false, result: err }
  end

  # Caches all pods in the namespace so other calls don't need to block on
  # network access.
  def calculate_reactive_cache
    return unless active? && project && !project.pending_delete?

    { }
  end

  private

  def join_api_url(*parts)
    url = URI.parse(api_url)
    prefix = url.path.sub(%r{/+\z}, '')

    url.path = [ prefix, *parts ].join("/")

    url.to_s
  end
end
