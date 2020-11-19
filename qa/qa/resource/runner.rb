# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Runner < Base
      attr_writer :name, :tags, :image, :executor, :executor_image
      attr_accessor :config, :token, :run_untagged

      attribute :id
      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-ci-cd'
          resource.description = 'Project with CI/CD Pipelines'
        end
      end

      def name
        @name || "qa-runner-#{SecureRandom.hex(4)}"
      end

      def image
        @image || 'gitlab/gitlab-runner:alpine'
      end

      def executor
        @executor || :shell
      end

      def executor_image
        @executor_image || 'registry.gitlab.com/gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.7'
      end

      def fabricate_via_api!
        Service::DockerRun::GitlabRunner.new(name).tap do |runner|
          runner.pull
          runner.token = @token ||= project.runners_token
          runner.address = Runtime::Scenario.gitlab_address
          runner.tags = @tags if @tags
          runner.image = image
          runner.config = config if config
          runner.executor = executor
          runner.executor_image = executor_image if executor == :docker
          runner.run_untagged = run_untagged if run_untagged
          runner.register!
        end
      end

      def remove_via_api!
        runners = project.runners(tag_list: @tags)
        unless runners && !runners.empty?
          raise "Project #{project.path_with_namespace} has no runners#{" with tags #{@tags}." if @tags&.any?}"
        end

        this_runner = runners.find { |runner| runner[:description] == name }
        unless this_runner
          raise "Project #{project.path_with_namespace} does not have a runner with a description matching #{name} #{"or tags #{@tags}" if @tags&.any?}. Runners available: #{runners}"
        end

        @id = this_runner[:id]

        super
      ensure
        Service::DockerRun::GitlabRunner.new(name).remove!
      end

      def api_delete_path
        "/runners/#{id}"
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
