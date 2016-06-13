class ServiceHook < WebHook
  belongs_to :service

  def execute(data)
    super(data, 'service_hook')
  end
end
