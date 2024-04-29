# frozen_string_literal: true

module QA
  module Resource
    class UserRunners < Base
      attr_accessor :run_untagged,
        :runner_type,
        :tag_list,
        :description,
        :executor_image,
        :image,
        :config,
        :executor

      attributes :id,
        :token,
        :token_expires_at,
        :project,
        :tag_list

      def initialize
        @tag_list = nil
        @config = nil
        @run_untagged = nil
        @description = "qa-runner-#{SecureRandom.hex(4)}"
        @executor = :shell
        @executor_image = "#{QA::Runtime::Env.container_registry_host}/#{QA::Runtime::Env.runner_container_namespace}/#{QA::Runtime::Env.gitlab_qa_build_image}" # rubocop:disable Layout/LineLength -- image path
      end

      def fabricate!
        fabricate_via_api!
      end

      def fabricate_via_api!
        api_post
        start_container_and_register
      end

      def remove_via_api!
        super
      ensure
        @docker_container.remove!
        @docker_container = nil
      end

      def api_get_path
        raise NotImplementedError
      end

      def api_post_path
        "/user/runners"
      end

      def api_delete_path
        "/runners/#{id}"
      end

      def api_post_body
        {
          runner_type: runner_type,
          run_untagged: run_untagged,
          tag_list: tag_list,
          project_id: project.id,
          description: description
        }
      end

      private

      def start_container_and_register
        @docker_container ||= Service::DockerRun::GitlabRunner.new(description).tap do |runner|
          runner.image = image if image

          Support::Retrier.retry_on_exception(sleep_interval: 5) do
            runner.pull
          end

          runner.token = token
          runner.address = Runtime::Scenario.gitlab_address
          runner.config = config if config
          runner.executor = executor
          runner.executor_image = executor_image if executor == :docker
          runner.run_untagged = run_untagged if run_untagged
          runner.register!
        end
      rescue StandardError => e
        @docker_container&.remove!
        raise(e)
      end
    end
  end
end
