require 'task_list'

class TaskList
  class Item
    COMPLETED = 'completed'.freeze
    INCOMPLETE = 'incomplete'.freeze

    def status_label
      complete? ? COMPLETED : INCOMPLETE
    end
  end
end
