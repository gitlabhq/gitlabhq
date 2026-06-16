# frozen_string_literal: true

require "base64"
require "securerandom"

module Gitlab
  module Orchestrator
    module Deployment
      module Services
        class Valkey
          include Helpers::Output
          include Helpers::Shell

          CHART_REPO_NAME = "valkey"
          CHART_REPO_URL = "https://valkey-io.github.io/valkey-helm"
          CHART_NAME = "valkey/valkey"

          attr_reader :host, :auth_secret_name, :auth_secret_key

          def initialize(kubeclient:, helm:, namespace:, release_name:)
            @kubeclient = kubeclient
            @helm = helm
            @namespace = namespace
            @release_name = release_name
            @auth_secret_name = "#{release_name}-auth"
            @auth_secret_key = "default"
            @host = "#{release_name}.#{namespace}.svc.cluster.local"
            @password = SecureRandom.hex(16)
          end

          def install
            log("Installing Valkey", :info, bright: true)
            create_auth_secret
            install_chart
          end

          def uninstall
            log("Uninstalling Valkey", :info)
            @helm.uninstall(@release_name, namespace: @namespace, timeout: "5m")
          rescue Helm::Client::Error => e
            log("Valkey uninstall failed: #{e.message}", :warn)
          end

          private

          def create_auth_secret
            log("Creating Valkey auth secret", :info)
            secret = Kubectl::Resources::Secret.new(@auth_secret_name, @auth_secret_key, @password)
            puts mask_secrets(@kubeclient.create_resource(secret), [@password, Base64.encode64(@password)])
          end

          def install_chart
            log("Adding Valkey Helm chart repo", :info)
            @helm.add_helm_chart(CHART_REPO_NAME, CHART_REPO_URL)

            values = {
              auth: {
                enabled: true,
                usersExistingSecret: @auth_secret_name,
                aclUsers: {
                  default: {
                    permissions: "~* &* +@all",
                    passwordKey: @auth_secret_key
                  }
                }
              },
              dataStorage: {
                enabled: true
              }
            }.deep_stringify_keys.to_yaml

            log("Installing Valkey Helm chart", :info)
            @helm.upgrade(@release_name, CHART_NAME,
              namespace: @namespace, timeout: "5m", values: values, args: ["--wait"])
          end
        end
      end
    end
  end
end
