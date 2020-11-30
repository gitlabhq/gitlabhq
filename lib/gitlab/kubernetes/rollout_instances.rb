# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class RolloutInstances
      include ::Gitlab::Utils::StrongMemoize

      def initialize(deployments, pods)
        @deployments = deployments
        @pods = pods
      end

      def pod_instances
        pods = matching_pods + extra_pending_pods

        pods.sort_by(&:order).map do |pod|
          to_hash(pod)
        end
      end

      private

      attr_reader :deployments, :pods

      def matching_pods
        strong_memoize(:matching_pods) do
          deployment_tracks = deployments.map(&:track)
          pods.select { |p| deployment_tracks.include?(p.track) }
        end
      end

      def extra_pending_pods
        wanted_instances = sum_hashes(deployments.map { |d| { d.track => d.wanted_instances } })
        present_instances = sum_hashes(matching_pods.map { |p| { p.track => 1 } })
        pending_instances = subtract_hashes(wanted_instances, present_instances)

        pending_instances.flat_map do |track, num|
          Array.new(num, pending_pod_for(track))
        end
      end

      def sum_hashes(hashes)
        hashes.reduce({}) do |memo, hash|
          memo.merge(hash) { |_key, memo_val, hash_val| memo_val + hash_val }
        end
      end

      def subtract_hashes(hash_a, hash_b)
        hash_a.merge(hash_b) { |_key, val_a, val_b| [0, val_a - val_b].max }
      end

      def pending_pod_for(track)
        ::Gitlab::Kubernetes::Pod.new({
          'status' => { 'phase' => 'Pending' },
          'metadata' => {
            'name' => 'Not provided',
            'labels' => {
              'track' => track
            }
          }
        })
      end

      def to_hash(pod)
        {
          status: pod.status&.downcase,
          pod_name: pod.name,
          tooltip: "#{pod.name} (#{pod.status})",
          track: pod.track,
          stable: pod.stable?
        }
      end
    end
  end
end
