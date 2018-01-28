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

        present paginate(namespaces), with: Entities::Namespace, current_user: current_user
      end

      desc 'Get a namespace by ID' do
        success Entities::Namespace
      end
      params do
        requires :id, type: String, desc: "Namespace's ID or path"
      end
      get ':id' do
        present user_namespace, with: Entities::Namespace, current_user: current_user
      end
    end
  end
end
