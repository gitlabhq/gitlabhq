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

  # users - The list of users to retrieve the todos for.
  # params - A Hash containing columns and values to use for filtering todos.
  def initialize(users, params = {})
    @users = users
    @params = params
  end

  def execute
    todos = Todo.for_user(users)
    todos = todos.pending
    todos = by_project(todos)
    todos = by_target_id(todos)
    todos = by_target_type(todos)
    todos = by_discussion(todos)
    by_commit_id(todos)
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
end
