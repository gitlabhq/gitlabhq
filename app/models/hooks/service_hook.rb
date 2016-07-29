class ServiceHook < WebHook
  belongs_to :service

  def execute(data, hook_name = 'service_hook')
    super(data, hook_name)
  end
end
