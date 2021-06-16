# frozen_string_literal: true

module Packages
  module Debian
    module DistributionKey
      extend ActiveSupport::Concern

      included do
        belongs_to :distribution, class_name: "Packages::Debian::#{container_type.capitalize}Distribution", inverse_of: :key
        validates :distribution,
          presence: true

        validates :private_key, presence: true, length: { maximum: 512.kilobytes }
        validates :passphrase, presence: true, length: { maximum: 255 }
        validates :public_key, presence: true, length: { maximum: 512.kilobytes }
        validates :fingerprint, presence: true, length: { maximum: 255 }

        validate :private_key_armored, :public_key_armored

        attr_encrypted :private_key,
          mode: :per_attribute_iv,
          key: Settings.attr_encrypted_db_key_base_32,
          algorithm: 'aes-256-gcm'
        attr_encrypted :passphrase,
          mode: :per_attribute_iv,
          key: Settings.attr_encrypted_db_key_base_32,
          algorithm: 'aes-256-gcm'

        private

        def private_key_armored
          if private_key.present? && !private_key.start_with?('-----BEGIN PGP PRIVATE KEY BLOCK-----')
            errors.add(:private_key, 'must be ASCII armored')
          end
        end

        def public_key_armored
          if public_key.present? && !public_key.start_with?('-----BEGIN PGP PUBLIC KEY BLOCK-----')
            errors.add(:public_key, 'must be ASCII armored')
          end
        end
      end
    end
  end
end
