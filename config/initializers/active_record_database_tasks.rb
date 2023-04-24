# frozen_string_literal: true

return unless Gitlab.ee?

ActiveSupport.on_load(:active_record) do
  Gitlab::Patch::AdditionalDatabaseTasks.patch!
end
