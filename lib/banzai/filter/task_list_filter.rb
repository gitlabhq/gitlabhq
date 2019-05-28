# frozen_string_literal: true

require 'task_list/filter'

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/behaviors/markdown/nodes/ordered_task_list.js
# - app/assets/javascripts/behaviors/markdown/nodes/task_list.js
# - app/assets/javascripts/behaviors/markdown/nodes/task_list_item.js
module Banzai
  module Filter
    class TaskListFilter < TaskList::Filter
    end
  end
end
