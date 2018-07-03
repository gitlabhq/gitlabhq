module Search
  class SnippetService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      snippets = SnippetsFinder.new(current_user).execute

      Gitlab::SnippetSearchResults.new(snippets, params[:search], per_page: params[:per_page])
    end

    def scope
      @scope ||= %w[snippet_titles].delete(params[:scope]) { 'snippet_blobs' }
    end
  end
end
