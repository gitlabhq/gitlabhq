# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

class Gitlab::BackgroundMigration::CreateGpgKeySubkeysFromGpgKeys
  class GpgKey < ActiveRecord::Base
    self.table_name = 'gpg_keys'

    include EachBatch
    include ShaAttribute

    sha_attribute :primary_keyid
    sha_attribute :fingerprint

    has_many :subkeys, class_name: 'GpgKeySubkey'
  end

  class GpgKeySubkey < ActiveRecord::Base
    self.table_name = 'gpg_key_subkeys'

    include ShaAttribute

    sha_attribute :keyid
    sha_attribute :fingerprint
  end

  def perform(gpg_key_id)
    gpg_key = GpgKey.find_by(id: gpg_key_id)

    return if gpg_key.nil?
    return if gpg_key.subkeys.any?

    create_subkeys(gpg_key)
    update_signatures(gpg_key)
  end

  private

  def create_subkeys(gpg_key)
    gpg_subkeys = Gitlab::Gpg.subkeys_from_key(gpg_key.key)

    gpg_subkeys[gpg_key.primary_keyid.upcase]&.each do |subkey_data|
      gpg_key.subkeys.build(keyid: subkey_data[:keyid], fingerprint: subkey_data[:fingerprint])
    end

    # Improve latency by doing all INSERTs in a single call
    GpgKey.transaction do
      gpg_key.save!
    end
  end

  def update_signatures(gpg_key)
    return unless gpg_key.subkeys.exists?

    InvalidGpgSignatureUpdateWorker.perform_async(gpg_key.id)
  end
end
