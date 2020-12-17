# frozen_string_literal: true

module API
  module Admin
    class InstanceClusters < ::API::Base
      include PaginationParams

      feature_category :kubernetes_management

      before do
        authenticated_as_admin!
      end

      namespace 'admin' do
        desc "Get list of all instance clusters" do
          detail "This feature was introduced in GitLab 13.2."
        end
        get '/clusters' do
          authorize! :read_cluster, clusterable_instance
          present paginate(clusters_for_current_user), with: Entities::Cluster
        end

        desc "Get a single instance cluster" do
          detail "This feature was introduced in GitLab 13.2."
        end
        params do
          requires :cluster_id, type: Integer, desc: "The cluster ID"
        end
        get '/clusters/:cluster_id' do
          authorize! :read_cluster, cluster

          present cluster, with: Entities::Cluster
        end

        desc "Add an instance cluster" do
          detail "This feature was introduced in GitLab 13.2."
        end
        params do
          requires :name, type: String, desc: 'Cluster name'
          optional :enabled, type: Boolean, default: true, desc: 'Determines if cluster is active or not, defaults to true'
          optional :environment_scope, default: '*', type: String, desc: 'The associated environment to the cluster'
          optional :namespace_per_environment, default: true, type: Boolean, desc: 'Deploy each environment to a separate Kubernetes namespace'
          optional :domain, type: String, desc: 'Cluster base domain'
          optional :management_project_id, type: Integer, desc: 'The ID of the management project'
          optional :managed, type: Boolean, default: true, desc: 'Determines if GitLab will manage namespaces and service accounts for this cluster, defaults to true'
          requires :platform_kubernetes_attributes, type: Hash, desc: %q(Platform Kubernetes data) do
            requires :api_url, type: String, allow_blank: false, desc: 'URL to access the Kubernetes API'
            requires :token, type: String, desc: 'Token to authenticate against Kubernetes'
            optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate)'
            optional :namespace, type: String, desc: 'Unique namespace related to Project'
            optional :authorization_type, type: String, values: ::Clusters::Platforms::Kubernetes.authorization_types.keys, default: 'rbac', desc: 'Cluster authorization type, defaults to RBAC'
          end
        end
        post '/clusters/add' do
          authorize! :add_cluster, clusterable_instance

          user_cluster = ::Clusters::CreateService
            .new(current_user, create_cluster_user_params)
            .execute

          if user_cluster.persisted?
            present user_cluster, with: Entities::Cluster
          else
            render_validation_error!(user_cluster)
          end
        end

        desc "Update an instance cluster" do
          detail "This feature was introduced in GitLab 13.2."
        end
        params do
          requires :cluster_id, type: Integer, desc: 'The cluster ID'
          optional :name, type: String, desc: 'Cluster name'
          optional :enabled, type: Boolean, desc: 'Enable or disable Gitlab\'s connection to your Kubernetes cluster'
          optional :environment_scope, type: String, desc: 'The associated environment to the cluster'
          optional :namespace_per_environment, default: true, type: Boolean, desc: 'Deploy each environment to a separate Kubernetes namespace'
          optional :domain, type: String, desc: 'Cluster base domain'
          optional :management_project_id, type: Integer, desc: 'The ID of the management project'
          optional :managed, type: Boolean, desc: 'Determines if GitLab will manage namespaces and service accounts for this cluster'
          optional :platform_kubernetes_attributes, type: Hash, desc: %q(Platform Kubernetes data) do
            optional :api_url, type: String, desc: 'URL to access the Kubernetes API'
            optional :token, type: String, desc: 'Token to authenticate against Kubernetes'
            optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate)'
            optional :namespace, type: String, desc: 'Unique namespace related to Project'
          end
        end
        put '/clusters/:cluster_id' do
          authorize! :update_cluster, cluster

          update_service = ::Clusters::UpdateService.new(current_user, update_cluster_params)

          if update_service.execute(cluster)
            present cluster, with: Entities::ClusterProject
          else
            render_validation_error!(cluster)
          end
        end

        desc "Remove a cluster" do
          detail "This feature was introduced in GitLab 13.2."
        end
        params do
          requires :cluster_id, type: Integer, desc: "The cluster ID"
        end
        delete '/clusters/:cluster_id' do
          authorize! :admin_cluster, cluster

          destroy_conditionally!(cluster)
        end
      end

      helpers do
        def clusterable_instance
          Clusters::Instance.new
        end

        def clusters_for_current_user
          @clusters_for_current_user ||= ClustersFinder.new(clusterable_instance, current_user, :all).execute
        end

        def cluster
          @cluster ||= clusters_for_current_user.find(params[:cluster_id])
        end

        def create_cluster_user_params
          declared_params.merge({
            provider_type: :user,
            platform_type: :kubernetes,
            clusterable: clusterable_instance
          })
        end

        def update_cluster_params
          declared_params(include_missing: false).without(:cluster_id)
        end
      end
    end
  end
end
