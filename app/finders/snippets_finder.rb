class SnippetsFinder
  def execute(current_user, params = {})
    filter = params[:filter]

    case filter
    when :all then
      snippets(current_user).fresh
    when :by_user then
      by_user(current_user, params[:user], params[:scope])
    when :by_project
      by_project(current_user, params[:project])
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

    return snippets.are_public unless current_user

    if user == current_user
      case scope
      when 'are_internal' then
        snippets.are_internal
      when 'are_private' then
        snippets.are_private
      when 'are_public' then
        snippets.are_public
      else
        snippets
      end
    else
      snippets.public_and_internal
    end
  end

  def by_project(current_user, project)
    snippets = project.snippets.fresh

    if current_user
      if project.team.member?(current_user.id)
        snippets
      else
        snippets.public_and_internal
      end
    else
      snippets.are_public
    end
  end
end
