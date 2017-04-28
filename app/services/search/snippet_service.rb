module Search
  class SnippetService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      snippets = SnippetsFinder.new(current_user).execute

      Gitlab::SnippetSearchResults.new(snippets, params[:search])
    end
  end
end
