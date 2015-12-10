require 'gitlab/markdown'
require 'task_list/filter'

module Gitlab
  module Markdown
    # Work around a bug in the default TaskList::Filter that adds a `task-list`
    # class to every list element, regardless of whether or not it contains a
    # task list.
    #
    # This is a (hopefully) temporary fix, pending a new release of the
    # task_list gem.
    #
    # See https://github.com/github/task_list/pull/60
    class TaskListFilter < TaskList::Filter
      def add_css_class(node, *new_class_names)
        if new_class_names.include?('task-list')
          super if node.children.any? { |c| c['class'] == 'task-list-item' }
        else
          super
        end
      end
    end
  end
end
