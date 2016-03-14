module Search
  class SnippetService
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      snippets = Snippet.accessible_to(current_user)

      if Gitlab.config.elasticsearch.enabled
        Gitlab::Elastic::SnippetSearchResults.new(snippets.pluck(:id),
                                                  params[:search])
      else
        Gitlab::SnippetSearchResults.new(snippets, params[:search])
      end
    end
  end
end
