# frozen_string_literal: true

class Gitlab::Serverless::Service
  include Gitlab::Utils::StrongMemoize

  def initialize(attributes)
    @attributes = attributes
  end

  def name
    @attributes.dig('metadata', 'name')
  end

  def namespace
    @attributes.dig('metadata', 'namespace')
  end

  def environment_scope
    @attributes.dig('environment_scope')
  end

  def environment
    @attributes.dig('environment')
  end

  def podcount
    @attributes.dig('podcount')
  end

  def created_at
    strong_memoize(:created_at) do
      timestamp = @attributes.dig('metadata', 'creationTimestamp')
      DateTime.parse(timestamp) if timestamp
    end
  end

  def image
    @attributes.dig(
      'spec',
      'runLatest',
      'configuration',
      'build',
      'template',
      'name')
  end

  def description
    knative_07_description || knative_05_06_description
  end

  def cluster
    @attributes.dig('cluster')
  end

  def url
    proxy_url || knative_06_07_url || knative_05_url
  end

  private

  def proxy_url
    if cluster&.serverless_domain
      Gitlab::Serverless::FunctionURI.new(function: name, cluster: cluster.serverless_domain, environment: environment)
    end
  end

  def knative_07_description
    @attributes.dig(
      'spec',
      'template',
      'metadata',
      'annotations',
      'Description'
    )
  end

  def knative_05_06_description
    @attributes.dig(
      'spec',
      'runLatest',
      'configuration',
      'revisionTemplate',
      'metadata',
      'annotations',
      'Description')
  end

  def knative_05_url
    domain = @attributes.dig('status', 'domain')
    return unless domain

    "http://#{domain}"
  end

  def knative_06_07_url
    @attributes.dig('status', 'url')
  end
end
