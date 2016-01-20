module Search
  class SnippetService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      snippet_ids = Snippet.accessible_to(current_user).pluck(:id)

      if Gitlab.config.elasticsearch.enabled
        Gitlab::Elastic::SnippetSearchResults.new(snippet_ids, params[:search])
      else  
        Gitlab::SnippetSearchResults.new(snippet_ids, params[:search])
      end
    end
  end
end
