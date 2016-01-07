require 'task_list/filter'

module Banzai
  module Filter
    # Work around a bug in the default TaskList::Filter that adds a `task-list`
    # class to every list element, regardless of whether or not it contains a
    # task list.
    #
    # This is a (hopefully) temporary fix, pending a new release of the
    # task_list gem.
    #
    # See https://github.com/github/task_list/pull/60
    class TaskListFilter < TaskList::Filter
      def add_css_class_with_fix(node, *new_class_names)
        if new_class_names.include?('task-list')
          # Don't add class to all lists
          return
        elsif new_class_names.include?('task-list-item')
          add_css_class_without_fix(node.parent, 'task-list')
        end

        add_css_class_without_fix(node, *new_class_names)
      end

      alias_method_chain :add_css_class, :fix
    end
  end
end
