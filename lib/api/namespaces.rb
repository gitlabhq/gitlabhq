module API
  # namespaces API
  class Namespaces < Grape::API
    before { authenticate! }

    resource :namespaces do
      desc 'Get a namespaces list' do
        succcess Entities::Namespace
      end
      get do
        namespaces = if current_user.admin
                        Namespace.all
                      else
                        current_user.namespaces
                      end

        namespaces = namespaces.search(params[:search]) if params[:search].present?

        present paginate(namespaces), with: Entities::Namespace
      end
    end
  end
end
