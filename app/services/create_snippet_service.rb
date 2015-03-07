class CreateSnippetService < BaseService
  def execute
    if project.nil?
      snippet = PersonalSnippet.new(params)
    else
      snippet = project.snippets.build(params)
    end

    unless Gitlab::VisibilityLevel.allowed_for?(current_user,
                                                params[:visibility_level])
      deny_visibility_level(snippet)
      return snippet
    end

    snippet.author = current_user

    snippet.save
    snippet
  end
end
