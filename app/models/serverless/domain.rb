# frozen_string_literal: true

module Serverless
  class Domain
    include ActiveModel::Model

    REGEXP = %r{^(?<scheme>https?://)?(?<function_name>[^.]+)-(?<cluster_left>\h{2})a1(?<cluster_middle>\h{10})f2(?<cluster_right>\h{2})(?<environment_id>\h+)-(?<environment_slug>[^.]+)\.(?<pages_domain_name>.+)}.freeze
    UUID_LENGTH = 14

    attr_accessor :function_name, :serverless_domain_cluster, :environment

    validates :function_name, presence: true, allow_blank: false
    validates :serverless_domain_cluster, presence: true
    validates :environment, presence: true

    def self.generate_uuid
      SecureRandom.hex(UUID_LENGTH / 2)
    end

    def uri
      URI("https://#{function_name}-#{serverless_domain_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{serverless_domain_cluster.domain}")
    end

    def knative_uri
      URI("http://#{function_name}.#{namespace}.#{serverless_domain_cluster.knative.hostname}")
    end

    private

    def namespace
      serverless_domain_cluster.cluster.kubernetes_namespace_for(environment)
    end

    def serverless_domain_cluster_uuid
      [
        serverless_domain_cluster.uuid[0..1],
        'a1',
        serverless_domain_cluster.uuid[2..-3],
        'f2',
        serverless_domain_cluster.uuid[-2..-1]
      ].join
    end
  end
end
