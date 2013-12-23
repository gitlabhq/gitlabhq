module API
  # namespaces API
  class Namespaces < Grape::API
    before {
      authenticate!
      authenticated_as_admin!
    }

    resource :namespaces do
      # Get a namespaces list
      #
      # Example Request:
      #  GET /namespaces
      get do
        @namespaces = Namespace.all
        @namespaces = @namespaces.search(params[:search]) if params[:search].present?
        @namespaces = paginate @namespaces

        present @namespaces, with: Entities::Namespace
      end
    end
  end
end
