# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSastIac < BaseSecurityAnalyzer
        graphql_name 'ConfigureSastIac'
        description <<~DESC
          Enable SAST IaC for a project in a new or
          modified `.gitlab-ci.yml` file in a new branch. The new
          branch and a URL to create a merge request are a part of the
          response.
        DESC

        def configure_analyzer(project, **_args)
          ::Security::CiConfiguration::SastIacCreateService.new(project, current_user).execute
        end
      end
    end
  end
end
