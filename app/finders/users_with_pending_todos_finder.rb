# frozen_string_literal: true

# Finder that given a target (e.g. an issue) finds all the users that have
# pending todos for said target.
class UsersWithPendingTodosFinder
  attr_reader :target

  # target - The target, such as an Issue or MergeRequest.
  def initialize(target)
    @target = target
  end

  def execute
    User.for_todos(target.todos.pending)
  end
end
