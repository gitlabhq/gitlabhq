module Search
  class SnippetService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      snippets = Snippet.accessible_to(current_user)

      Gitlab::SnippetSearchResults.new(snippets, params[:search])
    end
  end
end
