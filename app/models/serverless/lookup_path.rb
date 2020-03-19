# frozen_string_literal: true

module Serverless
  class LookupPath
    attr_reader :serverless_domain

    delegate :serverless_domain_cluster, to: :serverless_domain
    delegate :knative, to: :serverless_domain_cluster
    delegate :certificate, to: :serverless_domain_cluster
    delegate :key, to: :serverless_domain_cluster

    def initialize(serverless_domain)
      @serverless_domain = serverless_domain
    end

    def source
      {
        type: 'serverless',
        service: serverless_domain.knative_uri.host,
        cluster: {
          hostname: knative.hostname,
          address: knative.external_ip,
          port: 443,
          cert: certificate,
          key: key
        }
      }
    end
  end
end
