class ServiceHook < WebHook
  belongs_to :service
  validates :service, presence: true

  def execute(data)
    WebHookService.new(self, data, 'service_hook').execute
  end
end
