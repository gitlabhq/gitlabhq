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
  include Gitlab::Utils::StrongMemoize

  attr_accessor :current_user, :params
  delegate :explore, :only_personal, :only_project, :scope, :sort, to: :params

  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @params = OpenStruct.new(params)

    if project && author
      raise(
        ArgumentError,
        'Filtering by both an author and a project is not supported, ' \
          'as this finder is not optimised for this use case'
      )
    end
  end

  def execute
    # The snippet query can be expensive, therefore if the
    # author or project params have been passed and they don't
    # exist, or if a Project has been passed and has snippets
    # disabled, it's better to return
    return Snippet.none if author.nil? && params[:author].present?
    return Snippet.none if project.nil? && params[:project].present?
    return Snippet.none if project && !project.feature_available?(:snippets, current_user)

    items = init_collection
    items = by_ids(items)
    items = items.with_optional_visibility(visibility_from_scope)

    items.order_by(sort_param)
  end

  private

  def init_collection
    if explore
      snippets_for_explore
    elsif only_personal
      personal_snippets
    elsif project
      snippets_for_a_single_project
    else
      snippets_for_personal_and_multiple_projects
    end
  end

  # Produces a query that retrieves snippets for the Explore page
  #
  # We only show personal snippets here because this page is meant for
  # discovery, and project snippets are of limited interest here.
  def snippets_for_explore
    Snippet.public_to_user(current_user).only_personal_snippets
  end

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
  def snippets_for_personal_and_multiple_projects
    queries = []
    queries << personal_snippets unless only_project

    if Ability.allowed?(current_user, :read_cross_project)
      queries << snippets_of_visible_projects
      queries << snippets_of_authorized_projects if current_user
    end

    prepared_union(queries)
  end

  def snippets_for_a_single_project
    Snippet.for_project_with_user(project, current_user)
  end

  def personal_snippets
    snippets_for_author_or_visible_to_user.only_personal_snippets
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
    base = author ? author.snippets : Snippet.all

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
    case scope.to_s
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

  def by_ids(items)
    return items unless params[:ids].present?

    items.id_in(params[:ids])
  end

  def author
    strong_memoize(:author) do
      next unless params[:author].present?

      params[:author].is_a?(User) ? params[:author] : User.find_by_id(params[:author])
    end
  end

  def project
    strong_memoize(:project) do
      next unless params[:project].present?

      params[:project].is_a?(Project) ? params[:project] : Project.find_by_id(params[:project])
    end
  end

  def sort_param
    sort.presence || 'id_desc'
  end

  def prepared_union(queries)
    return Snippet.none if queries.empty?
    return queries.first if queries.length == 1

    # The queries are going to be part of a global `where`
    # therefore we only need to retrieve the `id` column
    # which will speed the query
    queries.map! { |rel| rel.select(:id) }
    Snippet.id_in(find_union(queries, Snippet))
  end
end

SnippetsFinder.prepend_mod_with('SnippetsFinder')
