# frozen_string_literal: true

module QA
  module Resource
    class Runner < Base
      attributes :id,
                 :active,
                 :paused,
                 :runner_type,
                 :online,
                 :status,
                 :ip_address,
                 :token,
                 :tags,
                 :config,
                 :run_untagged,
                 :name, # This attribute == runner[:description]
                 :image,
                 :executor,
                 :executor_image

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-ci-cd'
          resource.description = 'Project with CI/CD Pipelines'
        end
      end

      def initialize
        @tags = nil
        @config = nil
        @run_untagged = nil
        @name = "qa-runner-#{SecureRandom.hex(4)}"
        @image = 'registry.gitlab.com/gitlab-org/gitlab-runner:alpine'
        @executor = :shell
        @executor_image = 'registry.gitlab.com/gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.7'
      end

      # Initially we only support fabricate
      # via API
      def fabricate!
        fabricate_via_api!
      end

      # Start container and register runner
      # Fetch via API and populate attributes
      #
      def fabricate_via_api!
        start_container_and_register
        populate_runner_attributes
      end

      def remove_via_api!
        super
      ensure
        @docker_container.remove!
      end

      def reload!
        populate_runner_attributes
      end

      def api_delete_path
        "/runners/#{id}"
      end

      def api_get_path
        "/runners"
      end

      def api_post_path
        "/runners"
      end

      def api_post_body; end

      def not_found_by_tags?
        url = "#{api_get_path}?tag_list=#{tags.compact.join(',')}"
        auto_paginated_response(request_url(url)).empty?
      end

      def runners_list
        runners_list = nil
        url = tags ? "#{api_get_path}?tag_list=#{tags.compact.join(',')}" : api_get_path
        Runtime::Logger.info('Looking for list of runners via API...')
        Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1) do
          runners_list = auto_paginated_response(request_url(url))
          runners_list.present?
        end

        runners_list
      end

      def wait_until_online
        Runtime::Logger.info('Waiting for runner to come online...')
        Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1) do
          this_runner[:status] == 'online'
        end
      end

      def restart
        Runtime::Logger.info("Restarting runner container #{name}...")
        @docker_container.restart
        wait_until_online
      end

      private

      def start_container_and_register
        @docker_container = Service::DockerRun::GitlabRunner.new(name).tap do |runner|
          Support::Retrier.retry_on_exception(sleep_interval: 5) do
            runner.pull
          end

          runner.token = @token ||= project.runners_token
          runner.address = Runtime::Scenario.gitlab_address
          runner.tags = tags if tags
          runner.image = image
          runner.config = config if config
          runner.executor = executor
          runner.executor_image = executor_image if executor == :docker
          runner.run_untagged = run_untagged if run_untagged
          runner.register!
        end
      end

      def this_runner
        runner = nil
        Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1) do
          runner = runners_list.find { |runner| runner[:description] == name }
          !runner.nil?
        end
        runner
      end

      def populate_runner_attributes
        runner = this_runner
        @id = runner[:id]
        @active = runner[:active]
        @paused = runner[:paused]
        @runner_type = runner[:typed]
        @online = runner[:online]
        @status = runner[:status]
        @ip_address = runner[:ip_address]
      end
    end
  end
end
