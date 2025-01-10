# frozen_string_literal: true

module QA
  module Resource
    class UserRunners < Base
      attr_accessor :run_untagged,
        :runner_type,
        :tags,
        :name,
        :executor_image,
        :image,
        :config,
        :executor

      attributes :id,
        :token,
        :token_expires_at,
        :project,
        :group,
        :tag_list,
        :status,
        :online

      def initialize
        @tags = nil
        @config = nil
        @run_untagged = nil
        @name = "qa-runner-#{SecureRandom.hex(4)}"
        @executor = :shell
        @executor_image = "#{QA::Runtime::Env.container_registry_host}/#{QA::Runtime::Env.runner_container_namespace}/#{QA::Runtime::Env.gitlab_qa_build_image}"
      end

      def fabricate!
        fabricate_via_api!
      end

      def fabricate_via_api!
        api_post
        start_container_and_register
      end

      def unregister!
        unregister_runner
      end

      def remove_via_api!
        super
      ensure
        @docker_container.remove!
        @docker_container = nil
      end

      def api_get_path
        "/runners/#{id}"
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
          tag_list: tags || [],
          description: name,
          project_id: runner_type == 'project_type' ? project.id : nil,
          group_id: runner_type == 'group_type' ? group.id : nil
        }.compact
      end

      def wait_until_online
        Runtime::Logger.info('Waiting for runner to come online...')
        Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1) do
          reload! && status == 'online'
        end
      end

      def restart
        Runtime::Logger.info("Restarting runner container #{name}...")
        @docker_container.restart
        wait_until_online
      end

      private

      def start_container_and_register
        @docker_container ||= Service::DockerRun::GitlabRunner.new(name).tap do |runner|
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
        populate_initial_id
      rescue StandardError => e
        @docker_container&.remove!
        raise(e)
      end

      def unregister_runner
        raise "Cannot unregister runner: Docker container not initialized for runner '#{name}'" unless @docker_container

        @docker_container.run_unregister_command!
      end

      def populate_initial_id
        tag_list = tags ? { tag_list: tags.compact.join(',') } : {}
        runner = runner(**tag_list)
        Runtime::Logger.debug("Details of the runner fetched using tag_list: #{runner}")
        @id = runner[:id]
      end

      def runner(**kwargs)
        raise NotImplementedError
      end
    end
  end
end
