# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#server-object
      class Server
        attr_reader :url, :description, :variables

        def initialize(url:, description: nil, variables: nil)
          @url = url
          @description = description
          @variables = variables
        end

        def to_h
          hash = { url: url }
          hash[:description] = description if description.present?
          hash[:variables] = variables_to_h if variables.present?
          hash
        end

        private

        def variables_to_h
          variables.transform_values(&:to_h)
        end
      end
    end
  end
end
