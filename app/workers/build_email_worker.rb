class BuildEmailWorker
  include Sidekiq::Worker

  def perform(build_id, recipients, push_data)
    recipients.each do |recipient|
      begin
        case push_data['build_status']
        when 'success'
          Notify.build_success_email(build_id, recipient).deliver_now
        when 'failed'
          Notify.build_fail_email(build_id, recipient).deliver_now
        end
      # These are input errors and won't be corrected even if Sidekiq retries
      rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
        logger.info("Failed to send e-mail for project '#{push_data['project_name']}' to #{recipient}: #{e}")
      end
    end
  end
end
