class UseKeyWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(key_id)
    key = Key.find(key_id)
    key.touch(:last_used_at)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("UseKeyWorker: couldn't find key with ID=#{key_id}, skipping job")

    false
  end
end
