# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Instance
      module Configurations
        # Configuration for performing GitLab installation in a Docker container
        #
        class Gitlab < Base
          ADMIN_PASSWORD_ENV = "GITLAB_ROOT_PASSWORD"

          def initialize(
            image:,
            ci:,
            gitlab_domain:,
            admin_password:,
            host_http_port:
          )
            super(ci: ci, gitlab_domain: gitlab_domain)

            @image = image
            @admin_password = admin_password
            @host_http_port = host_http_port
          end

          # Run pre-installation setup
          #
          # @return [void]
          def run_pre_installation_setup; end

          # Run post-installation setup
          #
          # @return [void]
          def run_post_installation_setup
            wait_for_gitlab_ready
          end

          # Docker container configuration values
          #
          # @return [Hash]
          def values
            {
              image: image,
              environment: {
                GITLAB_OMNIBUS_CONFIG: omnibus_config,
                GITLAB_ROOT_PASSWORD: admin_password
              },
              ports: {
                "#{host_http_port}:80" => nil
              },
              restart: "always"
            }
          end

          # Gitlab url
          #
          # @return [String]
          def gitlab_url
            @gitlab_url ||= URI("http://#{gitlab_domain}:#{host_http_port}").to_s
          end

          private

          attr_reader :image, :admin_password, :host_http_port

          # Wait for GitLab to be ready
          #
          # @return [void]
          def wait_for_gitlab_ready
            Helpers::Spinner.spin("Waiting for GitLab to be ready. This may take a while...") do
              gitlab_ready = false

              30.times do
                begin
                  response = Net::HTTP.get_response(URI("#{gitlab_url}/users/sign_in"))
                  if response.code == "200"
                    log("GitLab is ready! 🚀", :success)
                    gitlab_ready = true
                    break
                  end
                rescue StandardError => e
                  log("GitLab is not ready yet. Reason: #{e.message}", :debug)
                end

                sleep 10 unless gitlab_ready
              end

              raise "Timed out waiting for GitLab to be ready" unless gitlab_ready
            end
          end

          # Docker client instance
          #
          # @return [Docker::Client]
          def docker_client
            @docker_client ||= ::Gitlab::Orchestrator::Docker::Client.new
          end

          # GitLab Omnibus configuration
          #
          # @return [String]
          def omnibus_config
            <<~RUBY
              external_url 'http://#{gitlab_domain}';
              gitlab_rails['gitlab_default_theme'] = 10;
              gitlab_rails['gitlab_disable_animations'] = true;
              gitlab_rails['application_settings_cache_seconds'] = 0;
              gitlab_rails['env']['GITLAB_LICENSE_MODE'] = 'test';
              gitlab_rails['env']['CUSTOMER_PORTAL_URL'] = 'https://customers.staging.gitlab.com';
              gitlab_rails['env']['GITLAB_ALLOW_SEPARATE_CI_DATABASE'] = 'false';
              gitlab_rails['env']['COVERBAND_ENABLED'] = 'false';
            RUBY
          end
        end
      end
    end
  end
end
