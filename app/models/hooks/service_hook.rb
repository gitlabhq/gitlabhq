# frozen_string_literal: true

class ServiceHook < WebHook
  belongs_to :service
  validates :service, presence: true

  # rubocop: disable CodeReuse/ServiceClass
<<<<<<< HEAD
  def execute(data, hook_name = 'service_hook')
    WebHookService.new(self, data, hook_name).execute
=======
  def execute(data)
    WebHookService.new(self, data, 'service_hook').execute
>>>>>>> upstream/master
  end
  # rubocop: enable CodeReuse/ServiceClass
end
