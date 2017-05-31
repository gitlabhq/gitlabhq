class ServiceHook < WebHook
  belongs_to :service

  def execute(data, hook_name = 'service_hook')
    WebHookService.new(self, data, hook_name).execute
  end
end
