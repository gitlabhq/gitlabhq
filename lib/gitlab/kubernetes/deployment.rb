# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class Deployment
      include Gitlab::Utils::StrongMemoize

      STABLE_TRACK_VALUE = 'stable'

      def initialize(attributes = {}, pods: [])
        @attributes = attributes
        @pods = pods
      end

      def name
        metadata['name'] || 'unknown'
      end

      def labels
        metadata.fetch('labels', {})
      end

      def annotations
        metadata.fetch('annotations', {})
      end

      def track
        labels.fetch('track', STABLE_TRACK_VALUE)
      end

      def stable?
        track == 'stable'
      end

      def order
        stable? ? 1 : 0
      end

      def outdated?
        observed_generation < generation
      end

      def wanted_instances
        spec.fetch('replicas', 0)
      end

      def created_instances
        filtered_pods_by_track.map do |pod|
          pod_metadata = pod.fetch('metadata', {})
          pod_name = pod_metadata['name'] || pod_metadata['generateName']
          pod_status = pod.dig('status', 'phase')

          deployment_instance(pod_name: pod_name, pod_status: pod_status)
        end
      end

      # These are replicas that did not get created yet,
      # So they still do not have any associated pod,
      # these are marked as pending instances.
      def not_created_instances
        pending_instances_count = wanted_instances - filtered_pods_by_track.count

        return [] if pending_instances_count <= 0

        Array.new(pending_instances_count, deployment_instance(pod_name: 'Not provided', pod_status: 'Pending'))
      end

      def filtered_pods_by_track
        strong_memoize(:filtered_pods_by_track) do
          @pods.select { |pod| has_same_track?(pod) }
        end
      end

      def instances
        created_instances + not_created_instances
      end

      private

      def deployment_instance(pod_name:, pod_status:)
        {
          status: pod_status&.downcase,
          pod_name: pod_name,
          tooltip: "#{pod_name} (#{pod_status})",
          track: track,
          stable: stable?
        }
      end

      def has_same_track?(pod)
        pod_track = pod.dig('metadata', 'labels', 'track') || STABLE_TRACK_VALUE

        pod_track == track
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

      def generation
        metadata.fetch('generation', 0)
      end

      def observed_generation
        status.fetch('observedGeneration', 0)
      end
    end
  end
end
