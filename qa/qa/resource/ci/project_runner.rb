# frozen_string_literal: true

module QA
  module Resource
    module Ci
      class ProjectRunner < UserRunners
        attribute :project do
          Project.fabricate_via_api! do |resource|
            resource.name = 'project-with-ci-cd'
            resource.description = 'Project with CI/CD Pipelines'
          end
        end

        attribute :runner_type do
          'project_type'
        end

        private

        def runner(**kwargs)
          fail_msg = "Wait for runner '#{name}' to register in project '#{project.name}'"
          Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1, message: fail_msg) do
            project.runners(**kwargs).find { |runner| runner[:description] == name }
          end
        end
      end
    end
  end
end
