# frozen_string_literal: true

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
        @image || 'registry.gitlab.com/gitlab-org/gitlab-runner:alpine'
      end

      def executor
        @executor || :shell
      end

      def executor_image
        @executor_image || 'registry.gitlab.com/gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.7'
      end

      def fabricate_via_api!
        @docker_container = Service::DockerRun::GitlabRunner.new(name).tap do |runner|
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
        runners = list_of_runners(tag_list: @tags)

        # If we have no runners, print the logs from the runner docker container in case they show why it isn't running.
        if runners.blank?
          dump_logs

          return
        end

        this_runner = runners.find { |runner| runner[:description] == name }

        # As above, but now we should have a specific runner. If not, print the logs from the runner docker container
        # to see if we can find out why the runner isn't running.
        unless this_runner
          dump_logs

          raise "Project #{project.path_with_namespace} does not have a runner with a description matching #{name} #{"or tags #{@tags}" if @tags&.any?}. Runners available: #{runners}"
        end

        @id = this_runner[:id]

        super
      ensure
        Service::DockerRun::GitlabRunner.new(name).remove!
      end

      def list_of_runners(tag_list: nil)
        url = tag_list ? "#{api_post_path}?tag_list=#{tag_list.compact.join(',')}" : api_post_path
        response = get(request_url(url, per_page: '100'))

        # Capturing 500 error code responses to log this issue better. We can consider cleaning it up once https://gitlab.com/gitlab-org/gitlab/-/issues/331753 is addressed.
        raise "Response returned a #{response.code} error code. #{response.body}" if response.code == Support::API::HTTP_STATUS_SERVER_ERROR

        parse_body(response)
      end

      def reload!
        super if method(:running?).super_method.call
      end

      def api_delete_path
        "/runners/#{id}"
      end

      def api_get_path
      end

      def api_post_path
        "/runners"
      end

      def api_post_body
      end

      private

      def dump_logs
        if @docker_container.running?
          @docker_container.logs { |line| QA::Runtime::Logger.debug(line) }
        else
          QA::Runtime::Logger.debug("No runner container found named #{name}")
        end
      end
    end
  end
end
