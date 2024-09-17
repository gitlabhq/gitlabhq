# frozen_string_literal: true

module API
  class ProjectClusters < ::API::Base
    include PaginationParams

    before do
      authenticate!
      ensure_feature_enabled!
    end

    feature_category :deployment_management
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List project clusters' do
        detail 'This feature was introduced in GitLab 11.7. Returns a list of project clusters.'
        success Entities::Cluster
        failure [
          { code: 403, message: 'Forbidden' }
        ]
        is_array true
        tags %w[clusters]
      end
      params do
        use :pagination
      end
      get ':id/clusters' do
        authorize! :read_cluster, user_project

        present paginate(clusters_for_current_user), with: Entities::Cluster
      end

      desc 'Get a single project cluster' do
        detail 'This feature was introduced in GitLab 11.7. Gets a single project cluster.'
        success Entities::ClusterProject
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[clusters]
      end
      params do
        requires :cluster_id, type: Integer, desc: 'The cluster ID'
      end
      get ':id/clusters/:cluster_id' do
        authorize! :read_cluster, cluster

        present cluster, with: Entities::ClusterProject
      end

      desc 'Add existing cluster to project' do
        detail 'This feature was introduced in GitLab 11.7. Adds an existing Kubernetes cluster to the project.'
        success Entities::ClusterProject
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
        optional :domain, type: String, desc: 'Cluster base domain'
        optional :environment_scope, default: '*', type: String, desc: 'The associated environment to the cluster'
        optional :namespace_per_environment, default: true, type: Boolean, desc: 'Deploy each environment to a separate Kubernetes namespace'
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
      post ':id/clusters/user' do
        authorize! :add_cluster, user_project

        user_cluster = ::Clusters::CreateService
          .new(current_user, create_cluster_user_params)
          .execute

        if user_cluster.persisted?
          present user_cluster, with: Entities::ClusterProject
        else
          render_validation_error!(user_cluster)
        end
      end

      desc 'Edit project cluster' do
        detail 'This feature was introduced in GitLab 11.7. Updates an existing project cluster.'
        success Entities::ClusterProject
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
        optional :domain, type: String, desc: 'Cluster base domain'
        optional :environment_scope, type: String, desc: 'The associated environment to the cluster'
        optional :namespace_per_environment, default: true, type: Boolean, desc: 'Deploy each environment to a separate Kubernetes namespace'
        optional :management_project_id, type: Integer, desc: 'The ID of the management project'
        optional :enabled, type: Boolean, desc: 'Determines if cluster is active or not'
        optional :managed, type: Boolean, desc: 'Determines if GitLab will manage namespaces and service accounts for this cluster'
        optional :platform_kubernetes_attributes, type: Hash, desc: 'Platform Kubernetes data' do
          optional :api_url, type: String, desc: 'URL to access the Kubernetes API'
          optional :token, type: String, desc: 'Token to authenticate against Kubernetes'
          optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate)'
          optional :namespace, type: String, desc: 'Unique namespace related to Project'
        end
      end
      put ':id/clusters/:cluster_id' do
        authorize! :update_cluster, cluster

        update_service = ::Clusters::UpdateService.new(current_user, update_cluster_params)

        if update_service.execute(cluster)
          present cluster, with: Entities::ClusterProject
        else
          render_validation_error!(cluster)
        end
      end

      desc 'Delete project cluster' do
        detail 'This feature was introduced in GitLab 11.7. Deletes an existing project cluster. Does not remove existing resources within the connected Kubernetes cluster.'
        success Entities::ClusterProject
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[clusters]
      end
      params do
        requires :cluster_id, type: Integer, desc: 'The Cluster ID'
      end
      delete ':id/clusters/:cluster_id' do
        authorize! :admin_cluster, cluster

        destroy_conditionally!(cluster)
      end
    end

    helpers do
      def clusters_for_current_user
        @clusters_for_current_user ||= ClustersFinder.new(user_project, current_user, :all).execute
      end

      def cluster
        @cluster ||= clusters_for_current_user.find(params[:cluster_id])
      end

      def create_cluster_user_params
        declared_params.merge({
          provider_type: :user,
          platform_type: :kubernetes,
          clusterable: user_project
        })
      end

      def update_cluster_params
        declared_params(include_missing: false).without(:cluster_id)
      end

      def ensure_feature_enabled!
        namespace = user_project.namespace

        not_found! unless namespace.certificate_based_clusters_enabled?
      end
    end
  end
end
