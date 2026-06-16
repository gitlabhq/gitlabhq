# frozen_string_literal: true

require "fileutils"
require "net/http"
require "json"
require "tmpdir"
require "uri"
require "securerandom"
require "socket"

module Gitlab
  module Orchestrator
    module Deployment
      module Services
        class Garage
          include Helpers::Output
          include Helpers::Shell

          CHART_REPO_URL = "https://github.com/deuxfleurs-org/garage"
          CHART_REPO_REF = "v2.3.0"
          CHART_PATH = "script/helm/garage"

          ADMIN_API_PORT = 3903
          S3_API_PORT = 3900
          LAYOUT_CAPACITY = 1_073_741_824
          WAIT_TIMEOUT = 300
          PORT_FORWARD_TIMEOUT = 30
          PORT_FORWARD_POLL_INTERVAL = 0.5

          BUCKETS = %w[
            git-lfs
            gitlab-artifacts
            gitlab-backups
            gitlab-ci-secure-files
            gitlab-dependency-proxy
            gitlab-mr-diffs
            gitlab-packages
            gitlab-pages
            gitlab-terraform-state
            gitlab-uploads
            registry
            runner-cache
            tmp
          ].freeze

          attr_reader :object_storage_secret_name,
            :s3cmd_secret_name,
            :registry_storage_secret_name

          def initialize(kubeclient:, helm:, namespace:, release_name:)
            @kubeclient = kubeclient
            @helm = helm
            @namespace = namespace
            @release_name = release_name
            @object_storage_secret_name = "#{release_name}-gitlab-object-storage"
            @s3cmd_secret_name = "#{release_name}-gitlab-object-storage-s3cmd"
            @registry_storage_secret_name = "#{release_name}-gitlab-registry-storage"
            @admin_token = SecureRandom.hex(32)
          end

          def install
            log("Installing Garage", :info, bright: true)
            fetch_chart
            install_chart
            wait_for_garage
            configure_garage
          end

          def uninstall
            log("Uninstalling Garage", :info)
            @helm.uninstall(@release_name, namespace: @namespace, timeout: "5m")
          rescue Helm::Client::Error => e
            log("Garage uninstall failed: #{e.message}", :warn)
          end

          private

          def fetch_chart
            log("Fetching Garage Helm chart from #{CHART_REPO_URL}", :info)
            @chart_dir = Dir.mktmpdir("garage-chart-")
            execute_shell([
              "git", "clone", "--depth=1", "--branch=#{CHART_REPO_REF}",
              "--filter=blob:none", "--sparse",
              CHART_REPO_URL, @chart_dir
            ])
            execute_shell(
              ["git", "-C", @chart_dir, "sparse-checkout", "set", CHART_PATH]
            )
          end

          def install_chart
            log("Installing Garage Helm chart", :info)
            values = {
              garage: {
                garageTomlString: garage_toml
              },
              deployment: {
                replicaCount: 1
              },
              persistence: {
                meta: { size: "100Mi" },
                data: { size: "500Mi" }
              }
            }.deep_stringify_keys.to_yaml

            @helm.upgrade(@release_name, File.join(@chart_dir, CHART_PATH),
              namespace: @namespace, timeout: "5m", values: values, args: ["--wait"])
          ensure
            FileUtils.rm_rf(@chart_dir) if @chart_dir
          end

          def garage_toml
            <<~TOML
              metadata_dir = "/mnt/meta"
              data_dir = "/mnt/data"
              db_engine = "sqlite"
              block_size = "1048576"
              replication_factor = 1
              consistency_mode = "consistent"
              compression_level = 1
              rpc_bind_addr = "[::]:3901"
              rpc_secret = "__RPC_SECRET_REPLACE__"
              bootstrap_peers = []

              [kubernetes_discovery]
              namespace = "#{@namespace}"
              service_name = "#{@release_name}"
              skip_crd = false

              [s3_api]
              s3_region = "garage"
              api_bind_addr = "[::]:#{S3_API_PORT}"
              root_domain = ".s3.garage.tld"

              [s3_web]
              bind_addr = "[::]:3902"
              root_domain = ".web.garage.tld"
              index = "index.html"

              [admin]
              api_bind_addr = "[::]:#{ADMIN_API_PORT}"
              admin_token = "#{@admin_token}"
            TOML
          end

          def wait_for_garage
            log("Waiting for Garage to become ready", :info)
            execute_shell([
              "kubectl", "wait", "pod",
              "-l", "app.kubernetes.io/instance=#{@release_name}",
              "-n", @namespace,
              "--for=condition=Ready",
              "--timeout=#{WAIT_TIMEOUT}s"
            ])
          end

          def configure_garage
            with_port_forward(ADMIN_API_PORT) do |local_port|
              endpoint = "http://localhost:#{local_port}"

              configure_layout(endpoint)

              key_data = create_api_key(endpoint, @admin_token)
              access_key_id = key_data["accessKeyId"]
              secret_access_key = key_data["secretAccessKey"]

              create_buckets(endpoint, @admin_token)
              grant_bucket_access(endpoint, @admin_token, access_key_id)

              s3_host = "#{@release_name}.#{@namespace}.svc.cluster.local"
              s3_endpoint = "http://#{s3_host}:#{S3_API_PORT}"

              create_object_storage_secret(s3_endpoint, access_key_id, secret_access_key)
              create_s3cmd_secret(s3_host, access_key_id, secret_access_key)
              create_registry_storage_secret(s3_endpoint, access_key_id, secret_access_key)
            end
          end

          def configure_layout(endpoint)
            log("Configuring Garage cluster layout", :info)
            status = garage_api(endpoint, @admin_token, "/v2/GetClusterStatus", method: :get)
            node_id = status["nodes"].find { |n| n["isUp"] }&.dig("id")
            raise "No active Garage node found" unless node_id

            garage_api(endpoint, @admin_token, "/v2/UpdateClusterLayout", method: :post,
              body: { roles: [{ id: node_id, zone: "dc1", capacity: LAYOUT_CAPACITY, tags: [] }] })
            garage_api(endpoint, @admin_token, "/v2/ApplyClusterLayout", method: :post,
              body: { version: 1 })
          end

          def with_port_forward(remote_port)
            local_port = available_port
            log("Port-forwarding localhost:#{local_port} -> #{@release_name}:#{remote_port}", :info)

            pid = Process.spawn(
              "kubectl", "port-forward",
              "#{@release_name}-0",
              "#{local_port}:#{remote_port}",
              "-n", @namespace,
              out: File::NULL, err: File::NULL
            )
            wait_for_port(local_port)

            yield local_port
          ensure
            if pid
              Process.kill("TERM", pid)
              Process.wait(pid)
            end
          end

          def available_port
            server = TCPServer.new("127.0.0.1", 0)
            server.addr[1]
          ensure
            server&.close
          end

          def wait_for_port(port)
            deadline = Time.now + PORT_FORWARD_TIMEOUT
            loop do
              TCPSocket.new("127.0.0.1", port).close
              return
            rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
              raise "Port-forward to localhost:#{port} not ready within #{PORT_FORWARD_TIMEOUT}s" if Time.now > deadline

              sleep(PORT_FORWARD_POLL_INTERVAL)
            end
          end

          def create_api_key(endpoint, admin_token)
            log("Creating Garage API key", :info)
            garage_api(endpoint, admin_token, "/v1/key", method: :post, body: { name: "gitlab" })
          end

          def create_buckets(endpoint, admin_token)
            log("Creating #{BUCKETS.length} Garage buckets", :info)
            BUCKETS.each do |bucket|
              result = garage_api(endpoint, admin_token, "/v1/bucket", method: :post, body: {})
              garage_api(endpoint, admin_token,
                "/v1/bucket/alias/global?id=#{result['id']}&alias=#{bucket}", method: :put)
            end
          end

          def grant_bucket_access(endpoint, admin_token, access_key_id)
            log("Granting bucket access to API key", :info)
            buckets = garage_api(endpoint, admin_token, "/v1/bucket?list", method: :get)
            buckets.each do |bucket|
              garage_api(endpoint, admin_token, "/v1/bucket/allow", method: :post,
                body: {
                  bucketId: bucket["id"],
                  accessKeyId: access_key_id,
                  permissions: { read: true, write: true, owner: true }
                })
            end
          end

          def create_object_storage_secret(s3_endpoint, access_key_id, secret_access_key)
            log("Creating object storage connection secret", :info)
            config = {
              provider: "AWS",
              aws_access_key_id: access_key_id,
              aws_secret_access_key: secret_access_key,
              aws_signature_version: 4,
              host: URI.parse(s3_endpoint).host,
              endpoint: s3_endpoint,
              path_style: true,
              region: "garage"
            }.deep_stringify_keys.to_yaml

            secret = Kubectl::Resources::Secret.new(@object_storage_secret_name, "config", config)
            puts mask_secrets(
              @kubeclient.create_resource(secret),
              [access_key_id, secret_access_key]
            )
          end

          def create_s3cmd_secret(s3_host, access_key_id, secret_access_key)
            log("Creating s3cmd config secret", :info)
            config = <<~S3CMD
              [default]
              access_key = #{access_key_id}
              secret_key = #{secret_access_key}
              bucket_location = garage
              host_base = #{s3_host}:#{S3_API_PORT}
              host_bucket = #{s3_host}:#{S3_API_PORT}
              use_https = False
              signature_v2 = False
            S3CMD

            secret = Kubectl::Resources::Secret.new(@s3cmd_secret_name, "config", config)
            puts mask_secrets(
              @kubeclient.create_resource(secret),
              [access_key_id, secret_access_key]
            )
          end

          def create_registry_storage_secret(s3_endpoint, access_key_id, secret_access_key)
            log("Creating registry storage secret", :info)
            config = {
              s3: {
                accesskey: access_key_id,
                secretkey: secret_access_key,
                bucket: "registry",
                region: "garage",
                regionendpoint: s3_endpoint,
                v4auth: true,
                pathstyle: true
              }
            }.deep_stringify_keys.to_yaml.delete_prefix("---\n")

            secret = Kubectl::Resources::Secret.new(@registry_storage_secret_name, "config", config)
            puts mask_secrets(
              @kubeclient.create_resource(secret),
              [access_key_id, secret_access_key]
            )
          end

          def garage_api(endpoint, admin_token, path, method: :get, body: nil)
            uri = URI("#{endpoint}#{path}")
            request = case method
                      when :get then Net::HTTP::Get.new(uri)
                      when :post then Net::HTTP::Post.new(uri)
                      when :put then Net::HTTP::Put.new(uri)
                      end

            request["Authorization"] = "Bearer #{admin_token}"
            request.content_type = "application/json" if body
            request.body = body.to_json if body

            response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
            unless response.is_a?(Net::HTTPSuccess)
              raise "Garage API #{method.upcase} #{path} failed: #{response.code} #{response.body}"
            end

            JSON.parse(response.body) if response.body && !response.body.empty?
          end
        end
      end
    end
  end
end
