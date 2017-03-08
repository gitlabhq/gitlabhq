module Gitlab
  module Kubernetes
    class Deployment
      def initialize(attributes = {})
        @attributes = attributes
      end

      def name
        metadata['name']
      end

      def labels
        metadata['labels']
      end

      def outdated?
        observed_generation < generation
      end

      def wanted_replicas
        spec.fetch('replicas', 0)
      end

      def finished_replicas
        status.fetch('availableReplicas', 0)
      end

      def deploying_replicas
        updated_replicas - finished_replicas
      end

      def waiting_replicas
        wanted_replicas - updated_replicas
      end

      def instances
        return deployment_instances(wanted_replicas, 'unknown', 'waiting') if name.nil?
        return deployment_instances(wanted_replicas, name, 'waiting') if outdated?

        out = deployment_instances(finished_replicas, name, 'finished')
        out.push(*deployment_instances(deploying_replicas, name, 'deploying', out.size))
        out.push(*deployment_instances(waiting_replicas, name, 'waiting', out.size))
        out
      end

      private

      def deployment_instances(n, name, status, offset = 0)
        return [] if n < 0

        Array.new(n) { |idx| deployment_instance(idx + offset, name, status) }
      end

      def deployment_instance(n, name, status)
        { status: status, tooltip: "#{name} (pod #{n}) #{status.capitalize}" }
      end

      def metadata
        @attributes.fetch('metadata', {})
      end

      def spec
        @attributes.fetch('spec', {})
      end

      def status
        @attributes.fetch('status', {})
      end

      def updated_replicas
        status.fetch('updatedReplicas', 0)
      end

      def generation
        metadata.fetch('generation', 0)
      end

      def observed_generation
        status.fetch('observedGeneration', 0)
      end
    end
  end
end
