class ServiceHook < WebHook
  belongs_to :service

  def execute(data)
    WebHookService.new(self, data, 'service_hook').execute
  end
end
