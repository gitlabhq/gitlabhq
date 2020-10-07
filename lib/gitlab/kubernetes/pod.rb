# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class Pod
      PENDING   = 'Pending'
      RUNNING   = 'Running'
      SUCCEEDED = 'Succeeded'
      FAILED    = 'Failed'
      UNKNOWN   = 'Unknown'
      PHASES    = [PENDING, RUNNING, SUCCEEDED, FAILED, UNKNOWN].freeze

      STABLE_TRACK_VALUE = 'stable'

      def initialize(attributes = {})
        @attributes = attributes
      end

      def track
        attributes.dig('metadata', 'labels', 'track') || STABLE_TRACK_VALUE
      end

      def name
        metadata['name'] || metadata['generateName']
      end

      def stable?
        track == STABLE_TRACK_VALUE
      end

      def status
        attributes.dig('status', 'phase')
      end

      def order
        stable? ? 1 : 0
      end

      private

      attr_reader :attributes

      def metadata
        attributes.fetch('metadata', {})
      end
    end
  end
end
