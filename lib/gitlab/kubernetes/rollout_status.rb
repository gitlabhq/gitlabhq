module Gitlab
  module Kubernetes
    # Calculates the rollout status for a set of kubernetes deployments.
    #
    # A GitLab environment may be composed of several Kubernetes deployments and
    # other resources, unified by an `app=` label. The rollout status sums the
    # Kubernetes deployments together.
    class RolloutStatus
      attr_reader :deployments, :instances, :completion

      def complete?
        completion == 100
      end

      def self.from_specs(*specs)
        deployments = specs.map { |spec| ::Gitlab::Kubernetes::Deployment.new(spec) }
        new(deployments)
      end

      def initialize(deployments)
        @deployments = deployments
        @instances = deployments.flat_map(&:instances)

        @completion =
          if @instances.empty?
            100
          else
            finished = @instances.select {|instance| instance[:status] == 'finished' }.count

            (finished / @instances.count.to_f * 100).to_i
          end
      end
    end
  end
end
