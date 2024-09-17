# frozen_string_literal: true

module API
  module Admin
    class InstanceClusters < ::API::Base
      include PaginationParams

      feature_category :deployment_management
      urgency :low

      before do
        authenticated_as_admin!
        ensure_feature_enabled!
      end

      namespace 'admin' do
        desc 'List instance clusters' do
          detail 'This feature was introduced in GitLab 13.2. Returns a list of instance clusters.'
          success Entities::Cluster
          failure [
            { code: 403, message: 'Forbidden' }
          ]
          is_array true
          tags %w[clusters]
        end
        get '/clusters' do
          authorize! :read_cluster, clusterable_instance
          present paginate(clusters_for_current_user), with: Entities::Cluster
        end

        desc 'Get a single instance cluster' do
          detail 'This feature was introduced in GitLab 13.2. Returns a single instance cluster.'
          success Entities::Cluster
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[clusters]
        end
        params do
          requires :cluster_id, type: Integer, desc: "The cluster ID"
        end
        get '/clusters/:cluster_id' do
          authorize! :read_cluster, cluster

          present cluster, with: Entities::Cluster
        end

        desc 'Add existing instance cluster' do
          detail 'This feature was introduced in GitLab 13.2. Adds an existing Kubernetes instance cluster.'
          success Entities::Cluster
          failure [
            { code: 400, message: 'Validation error' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[clusters]
        end
        params do
          requires :name, type: String, desc: 'Cluster name'
          optional :enabled, type: Boolean, default: true, desc: 'Determines if cluster is active or not, defaults to true'
          optional :environment_scope, default: '*', type: String, desc: 'The associated environment to the cluster'
          optional :namespace_per_environment, default: true, type: Boolean, desc: 'Deploy each environment to a separate Kubernetes namespace'
          optional :domain, type: String, desc: 'Cluster base domain'
          optional :management_project_id, type: Integer, desc: 'The ID of the management project'
          optional :managed, type: Boolean, default: true, desc: 'Determines if GitLab will manage namespaces and service accounts for this cluster, defaults to true'
          requires :platform_kubernetes_attributes, type: Hash, desc: 'Platform Kubernetes data' do
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

        desc 'Edit instance cluster' do
          detail 'This feature was introduced in GitLab 13.2. Updates an existing instance cluster.'
          success Entities::Cluster
          failure [
            { code: 400, message: 'Validation error' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[clusters]
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
          optional :platform_kubernetes_attributes, type: Hash, desc: 'Platform Kubernetes data' do
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

        desc 'Delete instance cluster' do
          detail 'This feature was introduced in GitLab 13.2. Deletes an existing instance cluster. Does not remove existing resources within the connected Kubernetes cluster.'
          success Entities::Cluster
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[clusters]
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
          ::Clusters::Instance.new
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

        def ensure_feature_enabled!
          not_found! unless clusterable_instance.certificate_based_clusters_enabled?
        end
      end
    end
  end
end
