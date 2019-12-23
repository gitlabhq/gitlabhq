# frozen_string_literal: true

module API
  class Namespaces < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      params :optional_list_params_ee do
        # EE::API::Namespaces would override this helper
      end

      # EE::API::Namespaces would override this method
      def custom_namespace_present_options
        {}
      end
    end

    prepend_if_ee('EE::API::Namespaces') # rubocop: disable Cop/InjectEnterpriseEditionModule

    resource :namespaces do
      desc 'Get a namespaces list' do
        success Entities::Namespace
      end
      params do
        optional :search, type: String, desc: "Search query for namespaces"

        use :pagination
        use :optional_list_params_ee
      end
      get do
        namespaces = current_user.admin ? Namespace.all : current_user.namespaces

        namespaces = namespaces.include_gitlab_subscription if Gitlab.ee?

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
    end
  end
end
