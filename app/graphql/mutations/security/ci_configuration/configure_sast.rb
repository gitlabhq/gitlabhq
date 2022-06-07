# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSast < BaseSecurityAnalyzer
        graphql_name 'ConfigureSast'
        description <<~DESC
          Configure SAST for a project by enabling SAST in a new or modified
          `.gitlab-ci.yml` file in a new branch. The new branch and a URL to
          create a Merge Request are a part of the response.
        DESC

        argument :configuration, ::Types::CiConfiguration::Sast::InputType,
          required: true,
          description: 'SAST CI configuration for the project.'

        def configure_analyzer(project, **args)
          ::Security::CiConfiguration::SastCreateService.new(project, current_user, args[:configuration].to_h).execute
        end
      end
    end
  end
end
