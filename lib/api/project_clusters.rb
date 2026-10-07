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
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all clusters in a project' do
        detail 'Lists all clusters in a specified project.'
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
      route_setting :authorization, permissions: :read_cluster, boundary_type: :project
      get ':id/clusters' do
        authorize! :read_cluster, user_project

        present paginate(clusters_for_current_user), with: Entities::Cluster
      end

      desc 'Retrieve a cluster from a project' do
        detail 'Retrieves a specified cluster in a project.'
        success Entities::ClusterProject
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[clusters]
      end
      params do
        requires :cluster_id, type: Integer, desc: 'ID of the cluster.'
      end
      route_setting :authorization, permissions: :read_cluster, boundary_type: :project
      get ':id/clusters/:cluster_id' do
        authorize! :read_cluster, cluster

        present cluster, with: Entities::ClusterProject
      end

      desc 'Add a cluster to a project' do
        detail 'Adds a cluster to a specified project.'
        success Entities::ClusterProject
        failure [
          { code: 400, message: 'Validation error' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[clusters]
      end
      params do
        requires :name, type: String, desc: 'Name of the cluster.'
        optional :enabled, type: Boolean, default: true, desc: "If `true`, the cluster is active and GitLab's connection to the Kubernetes cluster is enabled."
        optional :domain, type: String, desc: '[Base domain](https://docs.gitlab.com/user/project/clusters/gitlab_managed_clusters/#base-domain) of the cluster.'
        optional :environment_scope, default: '*', type: String, desc: 'Associated environment to the cluster. Premium and Ultimate only.'
        optional :namespace_per_environment, default: true, type: Boolean, desc: 'If `true`, deploys each environment to a separate Kubernetes namespace.'
        optional :management_project_id, type: Integer, desc: 'ID of the [management project](https://docs.gitlab.com/user/clusters/management_project/) for the cluster.'
        optional :managed, type: Boolean, default: true, desc: 'If `true`, GitLab manages namespaces and service accounts for this cluster.'
        requires :platform_kubernetes_attributes, type: Hash, desc: 'Platform Kubernetes data.' do
          requires :api_url, type: String, allow_blank: false, desc: 'URL to access the Kubernetes API.'
          requires :token, type: String, desc: 'Token to authenticate against Kubernetes.'
          optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate).'
          optional :namespace, type: String, desc: 'Kubernetes namespace that environments deploy to. If `managed` and `namespace_per_environment` are `true`, the environment slug is appended.'
          optional :authorization_type, type: String, values: ::Clusters::Platforms::Kubernetes.authorization_types.keys, default: 'rbac', desc: 'Cluster authorization type.'
        end
      end
      route_setting :authorization, permissions: :create_cluster, boundary_type: :project
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

      desc 'Update a cluster in a project' do
        detail 'Updates a cluster in a specified project.'
        success Entities::ClusterProject
        failure [
          { code: 400, message: 'Validation error' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[clusters]
      end
      params do
        requires :cluster_id, type: Integer, desc: 'ID of the cluster.'
        optional :name, type: String, desc: 'Name of the cluster.'
        optional :domain, type: String, desc: '[Base domain](https://docs.gitlab.com/user/project/clusters/gitlab_managed_clusters/#base-domain) of the cluster.'
        optional :environment_scope, type: String, desc: 'Associated environment to the cluster. Premium and Ultimate only.'
        optional :namespace_per_environment, default: true, type: Boolean, desc: 'If `true`, deploys each environment to a separate Kubernetes namespace.'
        optional :management_project_id, type: Integer, desc: 'ID of the [management project](https://docs.gitlab.com/user/clusters/management_project/) for the cluster.'
        optional :enabled, type: Boolean, desc: "If `true`, the cluster is active and GitLab's connection to the Kubernetes cluster is enabled."
        optional :managed, type: Boolean, desc: 'If `true`, GitLab manages namespaces and service accounts for this cluster.'
        optional :platform_kubernetes_attributes, type: Hash, desc: 'Platform Kubernetes data.' do
          optional :api_url, type: String, desc: 'URL to access the Kubernetes API.'
          optional :token, type: String, desc: 'Token to authenticate against Kubernetes.'
          optional :ca_cert, type: String, desc: 'TLS certificate (needed if API is using a self-signed TLS certificate).'
          optional :namespace, type: String, desc: 'Kubernetes namespace that environments deploy to. If `managed` and `namespace_per_environment` are `true`, the environment slug is appended.'
        end
      end
      route_setting :authorization, permissions: :update_cluster, boundary_type: :project
      put ':id/clusters/:cluster_id' do
        authorize! :update_cluster, cluster

        update_service = ::Clusters::UpdateService.new(current_user, update_cluster_params)

        if update_service.execute(cluster)
          present cluster, with: Entities::ClusterProject
        else
          render_validation_error!(cluster)
        end
      end

      desc 'Delete cluster from a project' do
        detail 'Deletes a specified cluster from a project. Does not remove existing resources in the connected ' \
          'Kubernetes cluster.'
        success Entities::ClusterProject
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[clusters]
      end
      params do
        requires :cluster_id, type: Integer, desc: 'ID of the cluster.'
      end
      route_setting :authorization, permissions: :delete_cluster, boundary_type: :project
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
