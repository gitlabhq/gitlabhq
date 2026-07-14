# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Deployment
      module Services
        class CloudNativePG
          include Helpers::Output
          include Helpers::Shell

          OPERATOR_CHART_REPO_NAME = "cnpg"
          OPERATOR_CHART_REPO_URL = "https://cloudnative-pg.github.io/charts"
          OPERATOR_CHART_NAME = "cnpg/cloudnative-pg"
          OPERATOR_RELEASE_NAME = "cnpg-operator"

          PG_IMAGE = "ghcr.io/cloudnative-pg/postgresql:17"
          DATABASE_NAME = "gitlabhq_production"
          DATABASE_OWNER = "gitlab"
          MAX_CONNECTIONS = 200
          PG_EXTENSIONS = %w[pg_trgm btree_gist plpgsql amcheck pg_stat_statements].freeze

          WAIT_TIMEOUT = 300
          POLL_INTERVAL = 5

          attr_reader :host, :password_secret_name, :password_secret_key

          # @param additional_databases [Array<Hash>] extra logical databases to bootstrap, each
          #   { name:, owner:, password: } - created as a role + database in this same cluster
          def initialize(kubeclient:, helm:, namespace:, cluster_name:, additional_databases: [])
            @kubeclient = kubeclient
            @helm = helm
            @namespace = namespace
            @cluster_name = cluster_name
            @additional_databases = additional_databases
            @host = "#{cluster_name}-rw.#{namespace}.svc.cluster.local"
            @password_secret_name = "#{cluster_name}-app"
            @password_secret_key = "password"
          end

          def install
            log("Installing CloudNativePG", :info, bright: true)
            install_operator
            wait_for_operator
            apply_cluster
            wait_for_cluster
          end

          def uninstall
            log("Uninstalling CloudNativePG", :info)
            delete_cluster
            uninstall_operator
          end

          private

          def install_operator
            log("Adding CNPG Helm chart repo", :info)
            @helm.add_helm_chart(OPERATOR_CHART_REPO_NAME, OPERATOR_CHART_REPO_URL)

            log("Installing CNPG operator", :info)
            @helm.upgrade(OPERATOR_RELEASE_NAME, OPERATOR_CHART_NAME,
              namespace: @namespace, timeout: "5m", values: "---\n", args: ["--wait"])
          end

          def wait_for_operator
            log("Waiting for CNPG operator to become ready", :info)
            execute_shell([
              "kubectl", "wait", "deployment",
              "-l", "app.kubernetes.io/instance=#{OPERATOR_RELEASE_NAME}",
              "-n", @namespace,
              "--for=condition=Available",
              "--timeout=#{WAIT_TIMEOUT}s"
            ])
          end

          def apply_cluster
            log("Applying CNPG Cluster resource", :info)
            resource = Kubectl::Resources::CustomResource.new(@cluster_name, cluster_manifest)
            @kubeclient.create_resource(resource)
          end

          def wait_for_cluster
            log("Waiting for CNPG cluster to become ready", :info)
            deadline = Time.now + WAIT_TIMEOUT
            loop do
              if cluster_ready?
                log("CNPG cluster is ready", :info)
                return
              end

              raise "Timed out waiting for CNPG cluster '#{@cluster_name}' to become ready" if Time.now > deadline

              sleep(POLL_INTERVAL)
            end
          end

          def cluster_ready?
            output = execute_shell([
              "kubectl", "get", "cluster", @cluster_name,
              "-n", @namespace,
              "-o", "jsonpath={.status.phase}"
            ], raise_on_failure: false)
            result = output.is_a?(Array) ? output.first : output
            result.strip == "Cluster in healthy state"
          end

          def delete_cluster
            log("Deleting CNPG cluster", :info)
            execute_shell([
              "kubectl", "delete", "cluster", @cluster_name,
              "-n", @namespace,
              "--ignore-not-found=true", "--wait"
            ], raise_on_failure: false)
          rescue Helpers::Shell::CommandFailure => e
            log("CNPG cluster deletion failed: #{e.message}", :warn)
          end

          def uninstall_operator
            log("Uninstalling CNPG operator", :info)
            @helm.uninstall(OPERATOR_RELEASE_NAME, namespace: @namespace, timeout: "5m")
          rescue Helm::Client::Error => e
            log("CNPG operator uninstall failed: #{e.message}", :warn)
          end

          def cluster_manifest
            initdb = {
              database: DATABASE_NAME,
              owner: DATABASE_OWNER,
              postInitApplicationSQL: PG_EXTENSIONS.map { |ext| "CREATE EXTENSION IF NOT EXISTS #{ext};" }
            }
            # postInitSQL runs as superuser, unlike postInitApplicationSQL; needed for CREATE ROLE/DATABASE
            initdb[:postInitSQL] = additional_databases_sql unless @additional_databases.empty?

            {
              apiVersion: "postgresql.cnpg.io/v1",
              kind: "Cluster",
              metadata: {
                name: @cluster_name,
                namespace: @namespace
              },
              spec: {
                instances: 1,
                imageName: PG_IMAGE,
                postgresql: {
                  parameters: {
                    max_connections: MAX_CONNECTIONS.to_s
                  }
                },
                bootstrap: {
                  initdb: initdb
                },
                storage: {
                  size: "5Gi"
                }
              }
            }
          end

          def additional_databases_sql
            @additional_databases.flat_map do |db|
              [
                "CREATE ROLE #{db[:owner]} LOGIN PASSWORD '#{db[:password].gsub("'", "''")}';",
                "CREATE DATABASE #{db[:name]} OWNER #{db[:owner]};"
              ]
            end
          end
        end
      end
    end
  end
end
