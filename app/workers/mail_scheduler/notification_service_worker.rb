require 'active_job/arguments'

module MailScheduler
  class NotificationServiceWorker
    include ApplicationWorker
    include MailSchedulerQueue

    def perform(meth, *args)
      deserialized_args = ActiveJob::Arguments.deserialize(args)

      notification_service.public_send(meth, *deserialized_args) # rubocop:disable GitlabSecurity/PublicSend
    rescue ActiveJob::DeserializationError
    end

    def self.perform_async(*args)
      super(*ActiveJob::Arguments.serialize(args))
    end
  end
end
