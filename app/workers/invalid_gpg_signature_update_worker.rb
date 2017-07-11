class InvalidGpgSignatureUpdateWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(gpg_key_id)
    gpg_key = GpgKey.find_by(id: gpg_key_id)

    unless gpg_key
      return Rails.logger.error("InvalidGpgSignatureUpdateWorker: couldn't find gpg_key with ID=#{gpg_key_id}, skipping job")
    end

    Gitlab::Gpg::InvalidGpgSignatureUpdater.new(gpg_key).run
  end
end
