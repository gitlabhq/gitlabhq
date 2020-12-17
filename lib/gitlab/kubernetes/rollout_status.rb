# frozen_string_literal: true

module Gitlab
  module Kubernetes
    # Calculates the rollout status for a set of kubernetes deployments.
    #
    # A GitLab environment may be composed of several Kubernetes deployments and
    # other resources. The rollout status sums the Kubernetes deployments
    # together.
    class RolloutStatus
      attr_reader :deployments, :instances, :completion, :status, :canary_ingress

      def complete?
        completion == 100
      end

      def loading?
        @status == :loading
      end

      def not_found?
        @status == :not_found
      end

      def found?
        @status == :found
      end

      def canary_ingress_exists?
        canary_ingress.present?
      end

      def self.from_deployments(*deployments_attrs, pods_attrs: [], ingresses: [])
        return new([], status: :not_found) if deployments_attrs.empty?

        deployments = deployments_attrs.map do |attrs|
          ::Gitlab::Kubernetes::Deployment.new(attrs, pods: pods_attrs)
        end
        deployments.sort_by!(&:order)

        pods = pods_attrs.map do |attrs|
          ::Gitlab::Kubernetes::Pod.new(attrs)
        end

        ingresses = ingresses.map { |ingress| ::Gitlab::Kubernetes::Ingress.new(ingress) }

        new(deployments, pods: pods, ingresses: ingresses)
      end

      def self.loading
        new([], status: :loading)
      end

      def initialize(deployments, pods: [], ingresses: [], status: :found)
        @status       = status
        @deployments  = deployments
        @instances = RolloutInstances.new(deployments, pods).pod_instances
        @canary_ingress = ingresses.find(&:canary?)

        @completion =
          if @instances.empty?
            100
          else
            # We downcase the pod status in Gitlab::Kubernetes::Deployment#deployment_instance
            finished = @instances.count { |instance| instance[:status] == ::Gitlab::Kubernetes::Pod::RUNNING.downcase }

            (finished / @instances.count.to_f * 100).to_i
          end
      end
    end
  end
end
