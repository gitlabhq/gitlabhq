# frozen_string_literal: true

module Gitlab
  # The +otp_key_base+ param is used to encrypt the User#otp_secret attribute.
  #
  # When +otp_key_base+ is changed, it invalidates the current encrypted values
  # of User#otp_secret. This class can be used to decrypt all the values with
  # the old key, encrypt them with the new key, and and update the database
  # with the new values.
  #
  # For persistence between runs, a CSV file is used with the following columns:
  #
  #   user_id, old_value, new_value
  #
  # Only the encrypted values are stored in this file.
  #
  # As users may have their 2FA settings changed at any time, this is only
  # guaranteed to be safe if run offline.
  class OtpKeyRotator
    HEADERS = %w[user_id old_value new_value].freeze

    attr_reader :filename

    # Create a new rotator. +filename+ is used to store values by +calculate!+,
    # and to update the database with new and old values in +apply!+ and
    # +rollback!+, respectively.
    def initialize(filename)
      @filename = filename
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def rotate!(old_key:, new_key:)
      old_key ||= Gitlab::Application.credentials.otp_key_base

      raise ArgumentError, "Old key is the same as the new key" if old_key == new_key
      raise ArgumentError, "New key is too short! Must be 256 bits" if new_key.size < 64

      write_csv do |csv|
        User.transaction do
          User.with_two_factor.in_batches do |relation| # rubocop: disable Cop/InBatches
            rows = relation.pluck(:id, :encrypted_otp_secret, :encrypted_otp_secret_iv, :encrypted_otp_secret_salt)
            rows.each do |row|
              user = %i[id ciphertext iv salt].zip(row).to_h
              new_value = reencrypt(user, old_key, new_key)

              User.where(id: user[:id]).update_all(encrypted_otp_secret: new_value)
              csv << [user[:id], user[:ciphertext], new_value]
            end
          end
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def rollback!
      User.transaction do
        CSV.foreach(filename, headers: HEADERS, return_headers: false) do |row|
          User.where(id: row['user_id']).update_all(encrypted_otp_secret: row['old_value'])
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    attr_reader :old_key, :new_key

    def otp_secret_settings
      @otp_secret_settings ||= User.attr_encrypted_attributes[:otp_secret]
    end

    def reencrypt(user, old_key, new_key)
      original = user[:ciphertext].unpack("m").join
      opts = {
        iv: user[:iv].unpack("m").join,
        salt: user[:salt].unpack("m").join,
        algorithm: otp_secret_settings[:algorithm],
        insecure_mode: otp_secret_settings[:insecure_mode]
      }

      decrypted = Encryptor.decrypt(original, opts.merge(key: old_key))
      encrypted = Encryptor.encrypt(decrypted, opts.merge(key: new_key))
      [encrypted].pack("m")
    end

    def write_csv(&blk)
      File.open(filename, "w") do |file|
        yield CSV.new(file, headers: HEADERS, write_headers: false)
      end
    end
  end
end
