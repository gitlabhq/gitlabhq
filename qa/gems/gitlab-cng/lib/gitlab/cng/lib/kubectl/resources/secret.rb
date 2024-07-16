# frozen_string_literal: true

require "base64"

module Gitlab
  module Cng
    module Kubectl
      module Resources
        class Secret < Base
          # Generic kubernetes secret resource
          #
          # @param [String] resource_name
          # @param [String] key
          # @param [String] data
          def initialize(resource_name, key, data)
            super(resource_name)

            @key = key
            @data = data
          end

          # Secret kubernetes resource
          #
          # @return [String] JSON representation of the secret resource
          def json
            @json ||= {
              kind: "Secret",
              apiVersion: "v1",
              metadata: {
                name: resource_name
              },
              data: {
                key => Base64.encode64(data)
              }
            }.to_json
          end

          private

          attr_reader :key, :data
        end
      end
    end
  end
end
