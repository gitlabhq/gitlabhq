# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Runner < Base
      attr_writer :name, :tags, :image

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-ci-cd'
          resource.description = 'Project with CI/CD Pipelines'
        end
      end

      def name
        @name || "qa-runner-#{SecureRandom.hex(4)}"
      end

      def tags
        @tags || %w[qa e2e]
      end

      def image
        @image || 'gitlab/gitlab-runner:alpine'
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)

        Service::Runner.new(name).tap do |runner|
          Page::Project::Settings::CICD.perform do |settings|
            settings.expand_runners_settings do |runners|
              runner.pull
              runner.token = runners.registration_token
              runner.address = runners.coordinator_address
              runner.tags = tags
              runner.image = image
              runner.register!
            end
          end
        end
      end
    end
  end
end
