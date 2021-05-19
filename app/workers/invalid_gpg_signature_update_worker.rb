# frozen_string_literal: true

class InvalidGpgSignatureUpdateWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :source_code_management
  weight 2

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(gpg_key_id)
    gpg_key = GpgKey.find_by(id: gpg_key_id)

    return unless gpg_key

    Gitlab::Gpg::InvalidGpgSignatureUpdater.new(gpg_key).run
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
