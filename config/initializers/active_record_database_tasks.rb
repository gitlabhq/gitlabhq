# frozen_string_literal: true

return unless Gitlab.ee?

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(Gitlab::Patch::GeoDatabaseTasks)
end
