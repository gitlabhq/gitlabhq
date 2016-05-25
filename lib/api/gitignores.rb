module API
  class Gitignores < Grape::API

    # Get the list of the available gitignore templates
    #
    # Example Request:
    #   GET /gitignores
    get 'gitignores' do
      present Gitlab::Gitignore.all, with: Entities::GitignoresList
    end

    # Get the text for a specific gitignore
    #
    # Parameters:
    #   name (required) - The name of a license
    #
    # Example Request:
    #   GET /gitignores/Elixir
    #
    get 'gitignores/:name' do
      required_attributes! [:name]

      gitignore = Gitlab::Gitignore.find(params[:name])
      not_found!('.gitignore') unless gitignore

      present gitignore, with: Entities::Gitignore
    end
  end
end
