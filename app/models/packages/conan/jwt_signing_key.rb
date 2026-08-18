# frozen_string_literal: true

# Stores the cell-local signing key(s) used to sign and verify the JWTs that
# the Conan client uses to authenticate with GitLab. New tokens are signed with
# the current (most recent) key, while verification accepts any stored key so a
# token signed with a previous key still validates after a key rotation. The
# key is only needed at application runtime, so it is treated as an application
# secret and persisted (encrypted) in the database rather than as an operational
# secret.
#
# This moves the signing key off db_key_base entirely (see
# https://gitlab.com/gitlab-org/gitlab/-/work_items/588633). The table is
# seeded with a freshly generated secret on first use, so tokens issued before
# this deploy stop validating; the Conan client re-authenticates automatically
# when that happens.
module Packages
  module Conan
    class JwtSigningKey < ApplicationRecord
      extend Gitlab::ExclusiveLeaseHelpers

      encrypts :secret_key

      prevent_from_serialization :secret_key

      validates :secret_key,
        presence: true,
        length: { maximum: 128 },
        format: { with: /\A[0-9a-f]+\z/, allow_nil: true, if: -> { secret_key.is_a?(String) } }

      validate :ensure_secret_key_is_string

      scope :ordered, -> { order(:id) }

      class << self
        # Secret used to sign newly issued tokens. The most recently created key
        # is the active signing key.
        def current_secret_key
          all_secret_keys.last
        end

        # All stored secrets, used to verify tokens so that tokens signed with a
        # previous key still validate after a key rotation.
        def all_secret_keys
          keys = usable_secret_keys

          if keys.empty?
            # A plain read here could land on a replica that hasn't caught up
            # with the write below yet, and see an empty table again.
            Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).use_primary do
              seed!
              keys = usable_secret_keys
            end
          end

          keys
        end

        private

        # Decrypts every stored row, dropping any that are blank or fail to
        # decrypt instead of letting one bad row sink the rest.
        def usable_secret_keys
          ordered.to_a.filter_map do |record|
            record.secret_key.presence
          rescue ActiveRecord::Encryption::Errors::Decryption => e
            Gitlab::ErrorTracking.track_exception(e)
            nil
          end
        end

        # Not just an upgrade shim: a fresh install's table starts empty too,
        # so whichever of current_secret_key/all_secret_keys runs first seeds
        # it. There's no migration point that covers every install, so this
        # stays permanently rather than being removable later.
        #
        # Locked so that concurrent requests hitting an empty table (e.g. at
        # deploy time) don't each insert their own key. `all_secret_keys`
        # re-reads the table afterwards rather than using this method's
        # return value, since the row may have been created by whichever
        # process won the lock, not this one.
        #
        # Checks usable_secret_keys rather than raw row existence, so a table
        # whose rows all fail to decrypt (e.g. after losing the encryption
        # key) self-heals with a fresh key instead of leaving
        # current_secret_key returning nil forever.
        def seed!
          in_lock("Packages::Conan::JwtSigningKey#seed!", ttl: 15.seconds, retries: 3, sleep_sec: 0.05.seconds) do
            create!(secret_key: SecureRandom.hex(64)) if usable_secret_keys.empty?
          end
        end
      end

      private

      # format/length validators coerce non-String values via #to_s before
      # checking, so they wouldn't catch e.g. an Integer secret_key.
      def ensure_secret_key_is_string
        errors.add(:secret_key, 'must be a string') unless secret_key.is_a?(String) || secret_key.nil?
      end
    end
  end
end
