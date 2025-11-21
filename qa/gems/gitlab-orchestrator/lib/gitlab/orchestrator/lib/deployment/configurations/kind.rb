# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Deployment
      module Configurations
        # Configuration for performing deployment setup on local kind cluster
        #
        class Kind < Base
          # @return [String] secret name for initial admin password
          ADMIN_PASSWORD_SECRET = "gitlab-initial-root-password"
          # @return [String] configmap name for pre-receive hook
          PRE_RECEIVE_HOOK_CONFIGMAP_NAME = "pre-receive-hook"
          # @return [String] pre-receive hook script used by e2e tests
          PRE_RECEIVE_HOOK = <<~'SH'
            #!/usr/bin/env bash

            if [[ $GL_PROJECT_PATH =~ 'reject-prereceive' ]]; then
              echo 'GL-HOOK-ERR: Custom error message rejecting prereceive hook for projects with GL_PROJECT_PATH matching pattern reject-prereceive'
              exit 1
            fi
          SH
          # @return [String] secret name for OAuth provider
          OAUTH_SECRET_NAME = "gitlab-oauth-github"

          # Instance of kind deployment configuration
          #
          # @param **args [Hash]
          #   @option args [String] :namespace Namespace used for deployment
          #   @option args [Boolean] :ci Run for CI environment
          #   @option args [String] :gitlab_domain Custom gitlab domain
          #   @option args [String] :admin_password Initial password for admin user
          #   @option args [String] :admin_token Initial PAT token for admin user
          #   @option args [Integer] :host_http_port HTTP port for gitlab pages
          #   @option args [Integer] :host_ssh_port SSH port for gitlab
          #   @option args [Integer] :host_registry_port Registry port for gitlab
          #   @option args [String] :resource_preset resource preset name
          def initialize(**args)
            super(**args.slice(:namespace, :ci, :gitlab_domain))

            @admin_password = args[:admin_password]
            @admin_token = args[:admin_token]
            @host_http_port = args[:host_http_port]
            @host_ssh_port = args[:host_ssh_port]
            @host_registry_port = args[:host_registry_port]
            @resource_preset = args[:resource_preset]
          end

          # Run pre-deployment setup
          #
          # @return [void]
          def run_pre_deployment_setup
            create_initial_root_password
            create_pre_receive_hook
            create_oauth_secret if oauth_enabled?
          end

          # Run post-deployment setup
          #
          # @return [void]
          def run_post_deployment_setup
            patch_registry_svc_port
            create_root_token
          end

          # Helm chart values specific to kind deployment
          #
          # @return [Hash]
          def values
            {
              global: {
                shell: {
                  port: host_ssh_port
                },
                pages: {
                  port: host_http_port
                },
                registry: {
                  port: host_registry_port
                },
                initialRootPassword: {
                  secret: ADMIN_PASSWORD_SECRET
                },
                gitaly: {
                  hooks: {
                    preReceive: {
                      configmap: PRE_RECEIVE_HOOK_CONFIGMAP_NAME
                    }
                  }
                }
              },
              "nginx-ingress": {
                controller: {
                  replicaCount: 1,
                  minAavailable: 1,
                  service: {
                    type: "NodePort",
                    nodePorts: {
                      "gitlab-shell": Orchestrator::Kind::Cluster.host_port_mapping(host_ssh_port),
                      http: Orchestrator::Kind::Cluster.host_port_mapping(host_http_port),
                      registry: Orchestrator::Kind::Cluster.host_port_mapping(host_registry_port)
                    }
                  }
                }
              }
            }.deep_merge(ResourcePresets.resource_values(resource_preset))
          end

          # Gitlab url
          #
          # @return [String]
          def gitlab_url
            @gitlab_url ||= URI("http://gitlab.#{gitlab_domain}:#{host_http_port}").to_s
          end

          private

          attr_reader :admin_password,
            :admin_token,
            :host_http_port,
            :host_ssh_port,
            :host_registry_port,
            :resource_preset

          # Token seed script for root user
          #
          # @return [String]
          def admin_pat_seed
            <<~RUBY
              Gitlab::Seeder.quiet do
                User.find_by(username: 'root').tap do |user|
                  params = {
                    scopes: Gitlab::Auth.all_available_scopes.map(&:to_s),
                    name: 'seeded-api-token'
                  }

                  user.personal_access_tokens.build(params).tap do |pat|
                    pat.expires_at = 365.days.from_now
                    pat.set_token("#{admin_token}")
                    pat.organization = Organizations::Organization.default_organization
                    pat.save!
                  end
                end
              end
            RUBY
          end

          # Create initial root password
          #
          # @return [void]
          def create_initial_root_password
            log("Creating admin user initial password secret", :info)
            secret = Kubectl::Resources::Secret.new(ADMIN_PASSWORD_SECRET, "password", admin_password)
            puts mask_secrets(kubeclient.create_resource(secret), [admin_password, Base64.encode64(admin_password)])
          end

          # Create pre-receive hook
          #
          # @return [void]
          def create_pre_receive_hook
            log("Creating pre-receive hook", :info)
            configmap = Kubectl::Resources::Configmap.new(PRE_RECEIVE_HOOK_CONFIGMAP_NAME, "hook.sh", PRE_RECEIVE_HOOK)
            puts kubeclient.create_resource(configmap)
          end

          # Create admin user personal access token
          #
          # @return [void]
          def create_root_token
            log("Creating admin user personal access token", :info)
            puts mask_secrets(
              kubeclient.execute("toolbox", ["gitlab-rails", "runner", admin_pat_seed], container: "toolbox"),
              [admin_token]
            ).strip
          rescue Kubectl::Client::Error => e
            token_exists_error = "duplicate key value violates unique constraint " \
              "\"index_personal_access_tokens_on_token_digest\""
            return log("Token already exists, skipping!", :warn) if e.message.include?(token_exists_error)

            raise e
          end

          def patch_registry_svc_port
            log("Patching registry service port", :info)
            patch_data = {
              spec: {
                type: 'NodePort',
                ports: [
                  {
                    name: 'registry',
                    port: 5000,
                    targetPort: 5000,
                    protocol: 'TCP',
                    nodePort: 32495
                  }
                ]
              }
            }.to_json
            puts kubeclient.patch('svc', 'gitlab-registry', patch_data)
          end

          # Create OAuth provider secret
          #
          # @return [void]
          def create_oauth_secret
            app_id = ENV['QA_GITHUB_OAUTH_APP_ID']
            app_secret = ENV['QA_GITHUB_OAUTH_APP_SECRET']

            if app_id.nil? || app_id.empty? || app_secret.nil? || app_secret.empty?
              raise "OAuth environment variables QA_GITHUB_OAUTH_APP_ID and QA_GITHUB_OAUTH_APP_SECRET must be set"
            end

            log("Creating OAuth provider secret", :info)

            provider_config = <<~YAML
              name: 'github'
              app_id: '#{ENV['QA_GITHUB_OAUTH_APP_ID']}'
              app_secret: '#{ENV['QA_GITHUB_OAUTH_APP_SECRET']}'
            YAML

            secret = Kubectl::Resources::Secret.new(OAUTH_SECRET_NAME, "provider", provider_config)
            secrets_to_mask = [ENV['QA_GITHUB_OAUTH_APP_ID'], ENV['QA_GITHUB_OAUTH_APP_SECRET']]
            puts mask_secrets(kubeclient.create_resource(secret), secrets_to_mask)
          end

          # Check if OAuth is enabled
          #
          # @return [Boolean]
          def oauth_enabled?
            ENV['QA_RSPEC_TAGS']&.include?('oauth')
          end
        end
      end
    end
  end
end
