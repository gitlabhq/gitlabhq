# frozen_string_literal: true

class ServerlessDomainFinder
  attr_reader :match, :serverless_domain_cluster, :environment

  def initialize(uri)
    @match = ::Serverless::Domain::REGEXP.match(uri)
  end

  def execute
    return unless serverless?

    @serverless_domain_cluster = ::Serverless::DomainCluster.for_uuid(serverless_domain_cluster_uuid)
    return unless serverless_domain_cluster&.knative&.external_ip

    @environment = ::Environment.for_id_and_slug(match[:environment_id].to_i(16), match[:environment_slug])
    return unless environment

    ::Serverless::Domain.new(
      function_name: match[:function_name],
      serverless_domain_cluster: serverless_domain_cluster,
      environment: environment
    )
  end

  def serverless_domain_cluster_uuid
    return unless serverless?

    match[:cluster_left] + match[:cluster_middle] + match[:cluster_right]
  end

  def serverless?
    !!match
  end
end
