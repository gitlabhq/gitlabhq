# frozen_string_literal: true

module Types
  module Ci
    class PipelineVariablesDefaultRoleTypeEnum < BaseEnum
      graphql_name 'PipelineVariablesDefaultRoleType'
      description 'Pipeline variables minimum override roles.'

      ProjectCiCdSetting::PIPELINE_VARIABLES_OVERRIDE_ROLES.keys.map(&:to_s).each do |role|
        value role.upcase, value: role, description: role.humanize
      end
    end
  end
end
