module Ci
  class Cluster < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include ReactiveCaching

    self.reactive_cache_key = ->(cluster) { [cluster.class.model_name.singular, cluster.project_id, cluster.id] }

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    belongs_to :service

    # after_save :clear_reactive_cache!

    def creation_status(access_token)
      with_reactive_cache(access_token) do |operation|
        {
          status: operation[:status],
          status_message: operation[:status_message]
        }
      end
    end

    def calculate_reactive_cache(access_token)
      return { status: 'INTEGRATED' } if service # If it's already done, we don't need to continue the following process

      api_client = GoogleApi::CloudPlatform::Client.new(access_token, nil)
      operation = api_client.projects_zones_operations(gcp_project_id, cluster_zone, gcp_operation_id)

      if operation&.status == 'DONE'
        # Get cluster details (end point, etc)
        gke_cluster = api_client.projects_zones_clusters_get(
          gcp_project_id, cluster_zone, cluster_name
        )

        # Get k8s token
        token = ''
        KubernetesService.new.tap do |ks|
          ks.api_url = 'https://' + gke_cluster.endpoint
          ks.ca_pem = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
          ks.username = gke_cluster.master_auth.username
          ks.password = gke_cluster.master_auth.password
          secrets = ks.read_secrets
          secrets.each do |secret|
            name = secret.dig('metadata', 'name')
            if /default-token/ =~ name
              token_base64 = secret.dig('data', 'token')
              token = Base64.decode64(token_base64)
              break
            end
          end
        end

        # k8s endpoint, ca_cert
        endpoint = 'https://' + gke_cluster.endpoint
        cluster_ca_certificate = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)

        # Update service
        kubernetes_service.attributes = {
          active: true,
          api_url: endpoint,
          ca_pem: cluster_ca_certificate,
          namespace: project_namespace,
          token: token
        }

        kubernetes_service.save!

        # Save info in cluster record
        update(
          enabled: true,
          service: kubernetes_service,
          username: gke_cluster.master_auth.username,
          password: gke_cluster.master_auth.password,
          token: token,
          ca_cert: cluster_ca_certificate,
          end_point: endpoint,
        )
      end

      puts "#{self.class.name} - #{__callee__}: operation.to_json: #{operation.to_json}"
      operation.to_h
    end

    def kubernetes_service
      @kubernetes_service ||= project.find_or_initialize_service('kubernetes')
    end
  end
end
