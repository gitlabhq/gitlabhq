# frozen_string_literal: true

ActiveRecord::Tasks::DatabaseTasks.structure_load_flags ||= []

flag = '--single-transaction'

unless ActiveRecord::Tasks::DatabaseTasks.structure_load_flags.include?(flag)
  ActiveRecord::Tasks::DatabaseTasks.structure_load_flags << flag
end
