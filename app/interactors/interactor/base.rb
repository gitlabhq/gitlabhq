class Interactor::Base
  include Interactor

  def abilities
    @abilities ||= begin
                     abilities = Six.new
                     abilities << Ability
                     abilities
                   end
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def stop_async_job(queue, job_id)
    if job_id.present?
      # Stop job, if running
      queue = Sidekiq::Queue.new(queue)

      queue.each do |job|
        job.delete if job.jid == job_id
      end
    end
  end

  def log_info(message)
    Gitlab::AppLogger.info message
  end

  def error(message)
    {
      message: message,
      status: :error
    }
  end

  def success(message = '')
    {
      message: message,
      status: :success
    }
  end
end
