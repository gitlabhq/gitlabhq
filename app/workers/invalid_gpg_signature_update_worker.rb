# frozen_string_literal: true

class InvalidGpgSignatureUpdateWorker
  include ApplicationWorker

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(gpg_key_id)
    gpg_key = GpgKey.find_by(id: gpg_key_id)

    return unless gpg_key

    Gitlab::Gpg::InvalidGpgSignatureUpdater.new(gpg_key).run
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
