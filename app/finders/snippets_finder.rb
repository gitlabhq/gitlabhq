class SnippetsFinder
  def execute(current_user, params = {})
    filter = params[:filter]
    user = params.fetch(:user, current_user)

    case filter
    when :all then
      snippets(current_user).fresh
    when :public then
      Snippet.are_public.fresh
    when :by_user then
      by_user(current_user, user, params[:scope])
    when :by_project
      by_project(current_user, params[:project], params[:scope])
    end
  end

  private

  def snippets(current_user)
    if current_user
      Snippet.public_and_internal
    else
      # Not authenticated
      #
      # Return only:
      #   public snippets
      Snippet.are_public
    end
  end

  def by_user(current_user, user, scope)
    snippets = user.snippets.fresh

    if current_user
      include_private = user == current_user
      by_scope(snippets, scope, include_private)
    else
      snippets.are_public
    end
  end

  def by_project(current_user, project, scope)
    snippets = project.snippets.fresh

    if current_user
      include_private = project.team.member?(current_user) || current_user.admin_or_auditor?
      by_scope(snippets, scope, include_private)
    else
      snippets.are_public
    end
  end

  def by_scope(snippets, scope = nil, include_private = false)
    case scope.to_s
    when 'are_private'
      include_private ? snippets.are_private : Snippet.none
    when 'are_internal'
      snippets.are_internal
    when 'are_public'
      snippets.are_public
    else
      include_private ? snippets : snippets.public_and_internal
    end
  end
end
