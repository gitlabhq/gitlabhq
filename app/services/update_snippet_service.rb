class UpdateSnippetService < BaseService
  attr_accessor :snippet

  def initialize(project = nil, user, snippet, params = {})
    super(project, user, params)
    @snippet = snippet
  end

  def execute
    # check that user is allowed to set specified visibility_level
    new_visibility = params[:visibility_level]
    if new_visibility && new_visibility != snippet.visibility_level
      unless can?(current_user, :change_visibility_level, snippet) &&
        Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)
        deny_visibility_level(snippet, new_visibility_level)
        return snippet
      end
    end

    snippet.update_attributes(params)
  end
end
