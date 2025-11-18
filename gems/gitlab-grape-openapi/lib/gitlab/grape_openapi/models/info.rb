# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Info
        attr_accessor :title, :description, :terms_of_service, :version

        def initialize(**options)
          @title = options[:title]
          @description = options[:description]
          @terms_of_service = options[:terms_of_service]
          @version = options[:version]
        end

        def to_h
          {
            title: title,
            description: description,
            termsOfService: terms_of_service,
            version: version
          }.compact
        end
      end
    end
  end
end
