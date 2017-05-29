class ServiceHook < WebHook
  belongs_to :service

<<<<<<< HEAD
  def execute(data, hook_name = 'service_hook')
    super(data, hook_name)
=======
  def execute(data)
    WebHookService.new(self, data, 'service_hook').execute
>>>>>>> ce-com/master
  end
end
