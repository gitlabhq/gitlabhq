# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Instance
      # Class handling all the pre and post installation setup steps and GitLab Docker container creation
      #
      class Installation
        include Helpers::Output
        include Helpers::Shell
        extend Helpers::Output
        extend Helpers::Shell

        TROUBLESHOOTING_LINK = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/gems/gitlab-orchestrator?ref_type=heads#troubleshooting"

        def initialize(name, configuration:, ci:, gitlab_domain:, timeout:, **args)
          @name = name
          @configuration = configuration
          @ci = ci
          @gitlab_domain = gitlab_domain
          @timeout = timeout
          @extra_env = args[:env] || []
          @retry_attempts = args[:retry] || 0
          @installation_attempts = 0
        end

        # Perform installation with all the additional setup
        #
        # @return [void]
        def create
          log("Creating docker container instance '#{name}'", :info, bright: true)
          run_pre_install_setup
          run_install
          run_post_install_setup

          log("Installation successful and GitLab is available via: #{configuration.gitlab_url}", :success,
            bright: true)
        rescue Gitlab::Orchestrator::Docker::Error
          exit(1)
        end

        private

        attr_reader :name,
          :configuration,
          :ci,
          :gitlab_domain,
          :timeout,
          :extra_env,
          :retry_attempts

        # Docker client instance
        #
        # @return [Docker::Client]
        def docker_client
          @docker_client ||= Docker::Client.new
        end

        # Additional environment variables for container
        #
        # @return [Hash]
        def env_values
          return {} if extra_env.empty?

          env = extra_env.map { |e| e.split("=") }.reject { |e| e.size != 2 }.to_h
          return {} if env.empty?

          env
        end

        # Execute pre-installation setup
        #
        # @return [void]
        def run_pre_install_setup
          Helpers::Spinner.spin("running pre-installation setup") do
            configuration.run_pre_installation_setup
          end
        end

        # Run Docker container creation
        #
        # @return [void]
        def run_install
          values = configuration.values.deep_merge({ environment: env_values })
          total_attempts = retry_attempts + 1

          Helpers::Spinner.spin("creating docker container") do
            total_attempts.times do |attempt|
              log("Pulling docker image: #{values[:image]}", :info)
              docker_client.pull_image(values[:image])

              begin
                docker_client.run_container(
                  name: name,
                  image: values[:image],
                  environment: values[:environment],
                  ports: values[:ports],
                  volumes: values[:volumes] || {},
                  restart: values[:restart],
                  additional_options: ["--shm-size", "256m"]
                )
                break
              rescue Gitlab::Orchestrator::Docker::Error => e
                if attempt >= retry_attempts
                  handle_install_failure(e)
                else
                  log("Installation failed, retrying...", :warn)
                  log("Error: #{e}", :warn)
                end
              end
            end
          end
        end

        # Execute post-installation setup
        #
        # @return [void]
        def run_post_install_setup
          configuration.run_post_installation_setup
        end

        # Handle Docker container creation failure
        #
        # @param [StandardError] error
        # @return [void]
        def handle_install_failure(error)
          log("Docker container creation failed!", :error)
          log("For more information on troubleshooting failures, see: '#{TROUBLESHOOTING_LINK}'", :warn)
          raise error
        end
      end
    end
  end
end
