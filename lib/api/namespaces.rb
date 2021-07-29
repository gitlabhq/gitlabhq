# frozen_string_literal: true

module API
  class Namespaces < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :subgroups

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
      desc 'Get a namespaces list' do
        success Entities::Namespace
      end
      params do
        optional :search, type: String, desc: "Search query for namespaces"
        optional :owned_only, type: Boolean, desc: "Owned namespaces only"

        use :pagination
        use :optional_list_params_ee
      end
      get do
        owned_only = params[:owned_only] == true

        namespaces = current_user.admin ? Namespace.all : current_user.namespaces(owned_only: owned_only)

        namespaces = namespaces.include_route

        namespaces = namespaces.include_gitlab_subscription_with_hosted_plan if Gitlab.ee?

        namespaces = namespaces.search(params[:search]) if params[:search].present?

        options = { with: Entities::Namespace, current_user: current_user }

        present paginate(namespaces), options.reverse_merge(custom_namespace_present_options)
      end

      desc 'Get a namespace by ID' do
        success Entities::Namespace
      end
      params do
        requires :id, type: String, desc: "Namespace's ID or path"
      end
      get ':id', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        user_namespace = find_namespace!(params[:id])

        present user_namespace, with: Entities::Namespace, current_user: current_user
      end

      desc 'Get existence of a namespace including alternative suggestions' do
        success Entities::NamespaceExistence
      end
      params do
        requires :namespace, type: String, desc: "Namespace's path"
        optional :parent_id, type: Integer, desc: "The ID of the parent namespace. If no ID is specified, only top-level namespaces are considered."
      end
      get ':namespace/exists', requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        namespace_path = params[:namespace]

        exists = Namespace.by_parent(params[:parent_id]).filter_by_path(namespace_path).exists?
        suggestions = exists ? [Namespace.clean_path(namespace_path)] : []

        present :exists, exists
        present :suggests, suggestions
      end
    end
  end
end
