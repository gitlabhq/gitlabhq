# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class Ingress
      include Gitlab::Utils::StrongMemoize

      # Canary Ingress Annotations https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary
      ANNOTATION_KEY_CANARY = 'nginx.ingress.kubernetes.io/canary'
      ANNOTATION_KEY_CANARY_WEIGHT = 'nginx.ingress.kubernetes.io/canary-weight'

      def initialize(attributes = {})
        @attributes = attributes
      end

      def canary?
        strong_memoize(:is_canary) do
          annotations.any? do |key, value|
            key == ANNOTATION_KEY_CANARY && value == 'true'
          end
        end
      end

      def canary_weight
        return unless canary?
        return unless annotations.key?(ANNOTATION_KEY_CANARY_WEIGHT)

        annotations[ANNOTATION_KEY_CANARY_WEIGHT].to_i
      end

      def name
        metadata['name']
      end

      private

      def metadata
        @attributes.fetch('metadata', {})
      end

      def annotations
        metadata.fetch('annotations', {})
      end
    end
  end
end
