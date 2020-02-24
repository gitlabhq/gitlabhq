# frozen_string_literal: true

module Serverless
  class VirtualDomain
    attr_reader :serverless_domain

    delegate :serverless_domain_cluster, to: :serverless_domain
    delegate :pages_domain, to: :serverless_domain_cluster
    delegate :certificate, to: :pages_domain
    delegate :key, to: :pages_domain

    def initialize(serverless_domain)
      @serverless_domain = serverless_domain
    end

    def lookup_paths
      [
        ::Serverless::LookupPath.new(serverless_domain)
      ]
    end
  end
end
