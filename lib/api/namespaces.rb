module API
  class Namespaces < Grape::API
    include PaginationParams

    before { authenticate! }

    resource :namespaces do
      desc 'Get a namespaces list' do
        success Entities::Namespace
      end
      params do
        optional :search, type: String, desc: "Search query for namespaces"
        use :pagination
      end
      get do
        namespaces = current_user.admin ? Namespace.all : current_user.namespaces

        namespaces = namespaces.search(params[:search]) if params[:search].present?

        present paginate(namespaces), with: Entities::Namespace
      end

      desc 'Update a namespace' do
        success Entities::Namespace
      end
      params do
        optional :plan, type: String, desc: "Namespace or Group plan"
      end
      put ':id' do
        authenticated_as_admin!

        namespace = find_namespace(params[:id])

        return not_found!('Namespace') unless namespace

        if namespace.update(declared_params)
          present namespace, with: Entities::Namespace, current_user: current_user
        else
          render_validation_error!(namespace)
        end
      end
    end
  end
end
