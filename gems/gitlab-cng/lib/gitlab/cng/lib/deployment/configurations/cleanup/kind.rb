# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      module Configurations
        module Cleanup
          class Kind < Base
            def run
              remove_password_secret
              remove_hook_configmap
            end

            private

            # Remove admin password secret
            #
            # @return [void]
            def remove_password_secret
              log("Removing secret '#{Configurations::Kind::ADMIN_PASSWORD_SECRET}'", :info)
              puts kubeclient.delete_resource("secret", Configurations::Kind::ADMIN_PASSWORD_SECRET)
            end

            # Remove pre-receive hook configmap
            #
            # @return [void]
            def remove_hook_configmap
              log("Removing configmap '#{Configurations::Kind::PRE_RECEIVE_HOOK_CONFIGMAP_NAME}'", :info)
              puts kubeclient.delete_resource('configmap', Configurations::Kind::PRE_RECEIVE_HOOK_CONFIGMAP_NAME)
            end
          end
        end
      end
    end
  end
end
