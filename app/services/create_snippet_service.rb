class CreateSnippetService < BaseService
  def execute
    snippet = if project
                project.snippets.build(params)
              else
                PersonalSnippet.new(params)
              end

    unless Gitlab::VisibilityLevel.allowed_for?(current_user, params[:visibility_level])
      deny_visibility_level(snippet)
      return snippet
    end

    snippet.author = current_user

    snippet.save
    snippet
  end
end
