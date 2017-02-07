class CreateSnippetService < BaseService
  def execute
    request = params.delete(:request)
    api = params.delete(:api)

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
    snippet.spam = SpamService.new(snippet, request).check(api)

    if snippet.save
      UserAgentDetailService.new(snippet, request).create
    end

    snippet
  end
end
