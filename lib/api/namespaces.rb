# frozen_string_literal: true

module API
  class Namespaces < ::API::Base
    include PaginationParams

    before { authenticate! }

    NAMESPACES_TAGS = %w[namespaces].freeze

    helpers do
      params :optional_list_params_ee do
        # EE::API::Namespaces would override this helper
      end

      # EE::API::Namespaces would override this method
      def custom_namespace_present_options
        {}
      end
    end

    prepend_mod_with('API::Namespaces') # rubocop: disable Cop/InjectEnterpriseEditionModule

    resource :namespaces do
      desc 'List namespaces' do
        detail 'Get a list of the namespaces of the authenticated user. If the user is an administrator, a list of all namespaces in the GitLab instance is shown.'
        success Entities::Namespace
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
        is_array true
        tags NAMESPACES_TAGS
      end
      params do
        optional :search, type: String, desc: 'Returns a list of namespaces the user is authorized to view based on the search criteria'
        optional :owned_only, type: Boolean, desc: 'In GitLab 14.2 and later, returns a list of owned namespaces only'
        optional :top_level_only, type: Boolean, default: false, desc: 'Only include top level namespaces'

        use :pagination
        use :optional_list_params_ee
      end
      get feature_category: :groups_and_projects, urgency: :low do
        owned_only = params[:owned_only] == true

        namespaces = current_user.admin ? Namespace.all : current_user.namespaces(owned_only: owned_only)

        namespaces = namespaces.top_level if params[:top_level_only]

        namespaces = namespaces.without_project_namespaces.include_route

        namespaces = namespaces.include_gitlab_subscription_with_hosted_plan if Gitlab.ee?

        namespaces = namespaces.search(params[:search]) if params[:search].present?

        options = { with: Entities::Namespace, current_user: current_user }

        present paginate(namespaces), options.reverse_merge(custom_namespace_present_options)
      end

      desc 'Get namespace by ID' do
        detail 'Get a namespace by ID'
        success Entities::Namespace
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags NAMESPACES_TAGS
      end
      params do
        requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the namespace'
      end
      get ':id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS, feature_category: :groups_and_projects, urgency: :low do
        user_namespace = find_namespace!(params[:id])

        present user_namespace, with: Entities::Namespace, current_user: current_user
      end

      desc 'Get existence of a namespace' do
        detail 'Get existence of a namespace by path. Suggests a new namespace path that does not already exist.'
        success Entities::NamespaceExistence
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
        tags NAMESPACES_TAGS
      end
      params do
        requires :id, type: String, desc: "Namespace’s path"
        optional :parent_id, type: Integer, desc: 'The ID of the parent namespace. If no ID is specified, only top-level namespaces are considered.'
      end
      get ':id/exists', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS, feature_category: :groups_and_projects, urgency: :low do
        check_rate_limit!(:namespace_exists, scope: current_user)

        namespace_path = params[:id]
        existing_namespaces_within_the_parent = Namespace.without_project_namespaces.by_parent(params[:parent_id])

        exists = existing_namespaces_within_the_parent.filter_by_path(namespace_path).exists? || ProjectSetting.unique_domain_exists?(namespace_path)
        suggestions = exists ? [Namespace.clean_path(namespace_path, limited_to: existing_namespaces_within_the_parent)] : []

        present :exists, exists
        present :suggests, suggestions
      end
    end
  end
end
