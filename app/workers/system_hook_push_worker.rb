# frozen_string_literal: true

class SystemHookPushWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :source_code_management

  def perform(push_data, hook_id)
    SystemHooksService.new.execute_hooks(push_data, hook_id)
  end
end
