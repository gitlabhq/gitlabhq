# frozen_string_literal: true

require "base64"

module Gitlab
  module Cng
    module Kubectl
      module Resources
        class Configmap < Base
          # Generic kubernetes configmap resource
          #
          # @param [String] resource_name
          # @param [String] key
          # @param [String] value
          def initialize(resource_name, key, value)
            super(resource_name)

            @key = key
            @value = value
          end

          # Configmap kubernetes resource
          #
          # @return [String] JSON representation of the configmap resource
          def json
            @json ||= {
              kind: "ConfigMap",
              apiVersion: "v1",
              metadata: {
                name: resource_name
              },
              data: {
                key => value
              }
            }.to_json
          end

          private

          attr_reader :key, :value
        end
      end
    end
  end
end
