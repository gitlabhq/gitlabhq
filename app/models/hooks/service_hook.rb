# frozen_string_literal: true

class ServiceHook < WebHook
  belongs_to :service
  validates :service, presence: true

  # rubocop: disable CodeReuse/ServiceClass
  def execute(data)
    WebHookService.new(self, data, 'service_hook').execute
  end
  # rubocop: enable CodeReuse/ServiceClass
end
