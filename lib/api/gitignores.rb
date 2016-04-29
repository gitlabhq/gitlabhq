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
    #   key (required) - The key of a license
    #
    # Example Request:
    #   GET /gitignores/elixir
    #
    get 'gitignores/:key' do
      required_attributes! [:key]

      gitignore = Gitlab::Gitignore.find(params[:key])
      not_found!('.gitignore') unless gitignore

      present gitignore, with: Entities::Gitignore
    end
  end
end
