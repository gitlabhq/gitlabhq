# frozen_string_literal: true

class ServiceHook < WebHook
  include Presentable

  belongs_to :service
  validates :service, presence: true

  # rubocop: disable CodeReuse/ServiceClass
  def execute(data, hook_name = 'service_hook')
    WebHookService.new(self, data, hook_name).execute
  end
  # rubocop: enable CodeReuse/ServiceClass
end
