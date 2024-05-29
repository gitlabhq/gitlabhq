# frozen_string_literal: true

module Gitlab
  module Cng
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

          # Run pre-deployment setup
          #
          # @return [void]
          def run_pre_deployment_setup
            create_initial_root_password
            create_pre_receive_hook
          end

          # Run post-deployment setup
          #
          # @return [void]
          def run_post_deployment_setup
            create_root_token
          end

          # Helm chart values specific to kind deployment
          #
          # @return [Hash]
          def values
            {
              global: {
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
                      "gitlab-shell": 32022,
                      http: 32080
                    }
                  }
                }
              }
            }
          end

          # Gitlab url
          #
          # @return [String]
          def gitlab_url
            "http://gitlab.#{gitlab_domain}#{ci ? '' : ':32080'}"
          end

          private

          # Gitlab initial admin password, defaults to commonly used password across development environments
          #
          # @return [String]
          def admin_password
            @admin_password ||= ENV["GITLAB_ADMIN_PASSWORD"] || "5iveL!fe"
          end

          # Gitlab admin user personal access token, defaults to value used in development seed data
          #
          # @return [String]
          def admin_token
            @admin_token ||= ENV["GITLAB_ADMIN_ACCESS_TOKEN"] || "ypCa3Dzb23o5nvsixwPA"
          end

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
          end
        end
      end
    end
  end
end
