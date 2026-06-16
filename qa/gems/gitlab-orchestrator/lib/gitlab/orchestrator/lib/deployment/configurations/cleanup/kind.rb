# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Deployment
      module Configurations
        module Cleanup
          class Kind < Base
            def run
              uninstall_external_services
              remove_password_secret
              remove_hook_configmap
            end

            private

            def helm
              @helm ||= Helm::Client.new
            end

            def uninstall_external_services
              Services::Garage.new(
                kubeclient: kubeclient, helm: helm, namespace: namespace,
                release_name: Configurations::Kind::GARAGE_RELEASE_SUFFIX
              ).uninstall

              Services::CloudNativePG.new(
                kubeclient: kubeclient, helm: helm, namespace: namespace,
                cluster_name: Configurations::Kind::CNPG_CLUSTER_SUFFIX
              ).uninstall

              Services::Valkey.new(
                kubeclient: kubeclient, helm: helm, namespace: namespace,
                release_name: Configurations::Kind::VALKEY_RELEASE_SUFFIX
              ).uninstall
            end

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
