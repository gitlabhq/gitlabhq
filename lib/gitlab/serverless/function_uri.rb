# frozen_string_literal: true

module Gitlab
  module Serverless
    class FunctionURI < URI::HTTPS
      SERVERLESS_DOMAIN_REGEXP = %r{^(?<scheme>https?://)?(?<function>[^.]+)-(?<cluster_left>\h{2})a1(?<cluster_middle>\h{10})f2(?<cluster_right>\h{2})(?<environment_id>\h+)-(?<environment_slug>[^.]+)\.(?<domain>.+)}.freeze

      attr_reader :function, :cluster, :environment

      def initialize(function: nil, cluster: nil, environment: nil)
        initialize_required_argument(:function, function)
        initialize_required_argument(:cluster, cluster)
        initialize_required_argument(:environment, environment)

        @host = "#{function}-#{cluster.uuid[0..1]}a1#{cluster.uuid[2..-3]}f2#{cluster.uuid[-2..-1]}#{"%x" % environment.id}-#{environment.slug}.#{cluster.domain}"

        super('https', nil, host, nil, nil, nil, nil, nil, nil)
      end

      def self.parse(uri)
        match = SERVERLESS_DOMAIN_REGEXP.match(uri)
        return unless match

        cluster = ::Serverless::DomainCluster.find(match[:cluster_left] + match[:cluster_middle] + match[:cluster_right])
        return unless cluster

        environment = ::Environment.find(match[:environment_id].to_i(16))
        return unless environment&.slug == match[:environment_slug]

        new(
          function: match[:function],
          cluster: cluster,
          environment: environment
        )
      end

      private

      def initialize_required_argument(name, value)
        raise ArgumentError.new("missing argument: #{name}") unless value

        instance_variable_set("@#{name}".to_sym, value)
      end
    end
  end
end
