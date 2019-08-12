# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Runner < Base
      attr_writer :name, :tags, :image
      attr_accessor :config

      attribute :project do
        Project.fabricate_via_api! do |resource|
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

      def fabricate_via_api!
        Service::Runner.new(name).tap do |runner|
          runner.pull
          runner.token = project.runners_token
          runner.address = Runtime::Scenario.gitlab_address
          runner.tags = tags
          runner.image = image
          runner.config = config if config
          runner.run_untagged = true
          runner.register!
        end
      end

      def api_get_path
      end

      def api_post_path
      end

      def api_post_body
      end
    end
  end
end
