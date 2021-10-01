# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class EnvironmentEntity < Grape::Entity
        format_with(:string, &:to_s)

        expose :id, format_with: :string
        expose :display_name, as: :displayName
        expose :type

        private

        alias_method :environment, :object
        delegate :project, to: :object

        def display_name
          "#{project.name}/#{environment.name}"
        end

        def type
          case environment.name
          when /\A(.*[^a-z0-9])?(staging|stage|stg|preprod|pre-prod|model|internal)([^a-z0-9].*)?\z/i
            'staging'
          when /\A(.*[^a-z0-9])?(prod|production|prd|live)([^a-z0-9].*)?\z/i
            'production'
          when /\A(.*[^a-z0-9])?(test|testing|tests|tst|integration|integ|intg|int|acceptance|accept|acpt|qa|qc|control|quality)([^a-z0-9].*)?\z/i
            'testing'
          when /\A(.*[^a-z0-9])?(dev|review|development)([^a-z0-9].*)?\z/i
            'development'
          else
            'unmapped'
          end
        end
      end
    end
  end
end
