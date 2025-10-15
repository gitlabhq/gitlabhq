# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#server-object
      class Server
        attr_reader :url, :description

        def initialize(url:, description: nil)
          @url = url
          @description = description
        end

        def to_h
          hash = { url: url }
          hash[:description] = description if description.present?
          hash
        end
      end
    end
  end
end
