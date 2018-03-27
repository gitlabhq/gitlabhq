class InvalidGpgSignatureUpdateWorker
  include ApplicationWorker

  def perform(gpg_key_id)
    gpg_key = GpgKey.find_by(id: gpg_key_id)

    return unless gpg_key

    Gitlab::Gpg::InvalidGpgSignatureUpdater.new(gpg_key).run
  end
end
