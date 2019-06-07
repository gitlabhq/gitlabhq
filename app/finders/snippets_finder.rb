# frozen_string_literal: true

# Finder for retrieving snippets that a user can see, optionally scoped to a
# project or snippets author.
#
# Basic usage:
#
#     user = User.find(1)
#
#     SnippetsFinder.new(user).execute
#
# To limit the snippets to a specific project, supply the `project:` option:
#
#     user = User.find(1)
#     project = Project.find(1)
#
#     SnippetsFinder.new(user, project: project).execute
#
# Limiting snippets to an author can be done by supplying the `author:` option:
#
#     user = User.find(1)
#     project = Project.find(1)
#
#     SnippetsFinder.new(user, author: user).execute
#
# To filter snippets using a specific visibility level, you can provide the
# `scope:` option:
#
#     user = User.find(1)
#     project = Project.find(1)
#
#     SnippetsFinder.new(user, author: user, scope: :are_public).execute
#
# Valid `scope:` values are:
#
# * `:are_private`
# * `:are_internal`
# * `:are_public`
#
# Any other value will be ignored.
class SnippetsFinder < UnionFinder
  include FinderMethods

  attr_accessor :current_user, :project, :author, :scope

  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @project = params[:project]
    @author = params[:author]
    @scope = params[:scope].to_s

    if project && author
      raise(
        ArgumentError,
        'Filtering by both an author and a project is not supported, ' \
          'as this finder is not optimised for this use case'
      )
    end
  end

  def execute
    base =
      if project
        snippets_for_a_single_project
      else
        snippets_for_multiple_projects
      end

    base.with_optional_visibility(visibility_from_scope).fresh
  end

  private

  # Produces a query that retrieves snippets from multiple projects.
  #
  # The resulting query will, depending on the user's permissions, include the
  # following collections of snippets:
  #
  # 1. Snippets that don't belong to any project.
  # 2. Snippets of projects that are visible to the current user (e.g. snippets
  #    in public projects).
  # 3. Snippets of projects that the current user is a member of.
  #
  # Each collection is constructed in isolation, allowing for greater control
  # over the resulting SQL query.
  def snippets_for_multiple_projects
    queries = [global_snippets]

    if Ability.allowed?(current_user, :read_cross_project)
      queries << snippets_of_visible_projects
      queries << snippets_of_authorized_projects if current_user
    end

    find_union(queries, Snippet)
  end

  def snippets_for_a_single_project
    Snippet.for_project_with_user(project, current_user)
  end

  def global_snippets
    snippets_for_author_or_visible_to_user.only_global_snippets
  end

  # Returns the snippets that the current user (logged in or not) can view.
  def snippets_of_visible_projects
    snippets_for_author_or_visible_to_user
      .only_include_projects_visible_to(current_user)
      .only_include_projects_with_snippets_enabled
  end

  # Returns the snippets that the currently logged in user has access to by
  # being a member of the project the snippets belong to.
  #
  # This method requires that `current_user` returns a `User` instead of `nil`,
  # and is optimised for this specific scenario.
  def snippets_of_authorized_projects
    base = author ? snippets_for_author : Snippet.all

    base
      .only_include_projects_with_snippets_enabled(include_private: true)
      .only_include_authorized_projects(current_user)
  end

  def snippets_for_author_or_visible_to_user
    if author
      snippets_for_author
    elsif current_user
      Snippet.visible_to_or_authored_by(current_user)
    else
      Snippet.public_to_user
    end
  end

  def snippets_for_author
    base = author.snippets

    if author == current_user
      # If the current user is also the author of all snippets, then we can
      # include private snippets.
      base
    else
      base.public_to_user(current_user)
    end
  end

  def visibility_from_scope
    case scope
    when 'are_private'
      Snippet::PRIVATE
    when 'are_internal'
      Snippet::INTERNAL
    when 'are_public'
      Snippet::PUBLIC
    else
      nil
    end
  end
end
