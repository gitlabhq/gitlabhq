# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSecretDetection < BaseSecurityAnalyzer
        graphql_name 'ConfigureSecretDetection'
        description <<~DESC
          Configure Secret Detection for a project by enabling Secret Detection
          in a new or modified `.gitlab-ci.yml` file in a new branch. The new
          branch and a URL to create a Merge Request are a part of the
          response.
        DESC

        def configure_analyzer(project, **_args)
          ::Security::CiConfiguration::SecretDetectionCreateService.new(project, current_user).execute
        end
      end
    end
  end
end
