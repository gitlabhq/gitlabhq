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

      desc "Get namespace's projects" do
        success Entities::BasicProjectDetails
      end
      params do
        requires :id, type: String, desc: "Namespace's ID or path"
        use :pagination
      end
      get ':id/projects' do
        finder = if user_namespace.kind == 'group'
                   GroupProjectsFinder.new(group: user_namespace, current_user: current_user, params: project_finder_params)
                 else
                   finder_params = project_finder_params.merge(user: user_namespace.owner)
                   ProjectsFinder.new(current_user: current_user, params: finder_params)
                 end

        present paginate(finder.execute), with: Entities::BasicProjectDetails, current_user: current_user
      end
    end
  end
end
