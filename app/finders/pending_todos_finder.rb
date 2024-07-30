# frozen_string_literal: true

# Finder for retrieving the pending todos of a user, optionally filtered using
# various fields.
#
# While this finder is a bit more verbose compared to use
# `where(params.slice(...))`, it allows us to decouple the input parameters from
# the actual column names. For example, if we ever decide to use separate
# columns for target types (e.g. `issue_id`, `merge_request_id`, etc), we no
# longer need to change _everything_ that uses this finder. Instead, we just
# change the various `by_*` methods in this finder, without having to touch
# everything that uses it.
class PendingTodosFinder
  attr_reader :users, :params

  # users - The list of users to retrieve the todos for. If nil is passed, it won't filter todos based on users
  # params - A Hash containing columns and values to use for filtering todos.
  def initialize(params = {})
    @params = params

    # To prevent N+1 queries when fetching the users of the PendingTodos.
    @preload_user_association = params.fetch(:preload_user_association, false)
  end

  def execute
    todos = Todo.pending_without_hidden
    todos = by_users(todos)
    todos = by_project(todos)
    todos = by_target_id(todos)
    todos = by_target_type(todos)
    todos = by_author_id(todos)
    todos = by_discussion(todos)
    todos = by_commit_id(todos)

    todos = todos.with_preloaded_user if @preload_user_association

    by_action(todos)
  end

  def by_users(todos)
    return todos unless params[:users].present?

    todos.for_user(params[:users])
  end

  def by_project(todos)
    if (id = params[:project_id])
      todos.for_project(id)
    else
      todos
    end
  end

  def by_target_id(todos)
    if (id = params[:target_id])
      todos.for_target(id)
    else
      todos
    end
  end

  def by_target_type(todos)
    if (type = params[:target_type])
      todos.for_type(type)
    else
      todos
    end
  end

  def by_author_id(todos)
    return todos unless params[:author_id]

    todos.for_author(params[:author_id])
  end

  def by_commit_id(todos)
    if (id = params[:commit_id])
      todos.for_commit(id)
    else
      todos
    end
  end

  def by_discussion(todos)
    if (discussion = params[:discussion])
      todos.for_note(discussion.notes)
    else
      todos
    end
  end

  def by_action(todos)
    return todos if params[:action].blank?

    todos.for_action(params[:action])
  end
end
