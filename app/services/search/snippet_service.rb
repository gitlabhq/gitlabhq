module Search
  class SnippetService
    include Gitlab::CurrentSettings
    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      if current_application_settings.elasticsearch_search?
        Gitlab::Elastic::SnippetSearchResults.new(current_user,
                                                  params[:search])
      else
        snippets = Snippet.accessible_to(current_user)
        Gitlab::SnippetSearchResults.new(snippets, params[:search])
      end
    end
  end
end
