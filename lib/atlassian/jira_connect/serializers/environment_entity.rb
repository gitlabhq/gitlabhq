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
          environment.tier == 'other' ? 'unmapped' : environment.tier
        end
      end
    end
  end
end
