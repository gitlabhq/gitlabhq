# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      module Configurations
        # Configuration for performing deployment setup on local kind cluster
        #
        class Kind < Base
          ADMIN_PASSWORD_SECRET = "gitlab-initial-root-password"
          PRE_RECEIVE_HOOK_CONFIGMAP_NAME = "pre-receive-hook"

          skip_post_deployment_setup!

          def run_pre_deployment_setup
            create_initial_root_password
            create_pre_receive_hook
          end

          private

          # Pre-receive hook script used by e2e tests to test global git hooks
          #
          # @return [String]
          def pre_receive_hook
            <<~SH
              #!/usr/bin/env bash

              if [[ $GL_PROJECT_PATH =~ 'reject-prereceive' ]]; then
                echo 'GL-HOOK-ERR: Custom error message rejecting prereceive hook for projects with GL_PROJECT_PATH matching pattern reject-prereceive'
                exit 1
              fi
            SH
          end

          # Create initial root password
          #
          # @return [void]
          def create_initial_root_password
            admin_password = ENV["GITLAB_ADMIN_PASSWORD"]

            log("Creating initial root password secret", :info)
            return log("`GITLAB_ADMIN_PASSWORD` variable is not set, skipping", :warn) unless admin_password

            secret = Kubectl::Resources::Secret.new(ADMIN_PASSWORD_SECRET, "password", admin_password)
            puts mask_secrets(kubeclient.create_resource(secret), [admin_password, Base64.encode64(admin_password)])
          end

          # Create pre-receive hook
          #
          # @return [void]
          def create_pre_receive_hook
            log("Creating pre-receive hook", :info)
            configmap = Kubectl::Resources::Configmap.new(PRE_RECEIVE_HOOK_CONFIGMAP_NAME, "hook.sh", pre_receive_hook)
            puts kubeclient.create_resource(configmap)
          end
        end
      end
    end
  end
end
