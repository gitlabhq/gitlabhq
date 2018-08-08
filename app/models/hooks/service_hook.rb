# frozen_string_literal: true

class ServiceHook < WebHook
  belongs_to :service
  validates :service, presence: true

  def execute(data, hook_name = 'service_hook')
    WebHookService.new(self, data, hook_name).execute
  end
end
