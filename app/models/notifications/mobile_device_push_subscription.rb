# frozen_string_literal: true

module Notifications
  class MobileDevicePushSubscription < ApplicationRecord
    include EachBatch

    MAX_SUBSCRIPTIONS_PER_USER = 20
    DEVICE_TOKEN_REGEX = /\A[0-9a-f]{16,200}\z/

    belongs_to :user

    # APNs must receive the raw token at delivery time, so the token is
    # encrypted at rest rather than hashed. Deterministic encryption yields
    # stable ciphertext, which keeps the unique index and token lookups working.
    encrypts :device_token, deterministic: true

    # APNs tokens are opaque hex; clients disagree on casing. Uniqueness is
    # enforced on ciphertext, so normalize to lowercase to keep one row per
    # device. Normalization also applies to finder values, so lookups match
    # regardless of the caller's casing.
    normalizes :device_token, with: ->(token) { token.downcase }

    enum :platform, { ios: 0 }
    enum :apns_environment, { production: 0, sandbox: 1 }, prefix: :apns
    enum :payload_mode, { full: 0, id_only: 1 }, suffix: :payload

    validates :device_token, presence: true,
      format: { with: DEVICE_TOKEN_REGEX, message: 'must be a hexadecimal APNs device token' }
    validates :bundle_identifier, length: { maximum: 255 }
    validates :device_name, length: { maximum: 255 }
    validates :app_version, length: { maximum: 64 }
    validates :locale, length: { maximum: 32 }
    # The cap applies on create and on reassignment (a device changing hands
    # via `register` is an update that moves the row to a new user). A single
    # registration with a combined condition: declaring the same validation
    # method twice with different `on:` options makes the second registration
    # replace the first (ActiveSupport callback dedup).
    validate :subscriptions_limit, if: -> { new_record? || user_id_changed? }

    scope :with_device_token, ->(device_token) { where(device_token: device_token) }

    # A device registration is identified by (device_token, apns_environment):
    # the same physical device holds different tokens per environment.
    def self.find_or_initialize_for_device(device_token, apns_environment)
      find_or_initialize_by(device_token: device_token, apns_environment: apns_environment)
    end

    # Subscriptions whose device has not re-registered since the cutoff.
    # last_seen_at is written on every registration and defaults to the row's
    # creation time, so it is never NULL.
    scope :stale, ->(cutoff) { where(last_seen_at: ...cutoff) }

    private

    def subscriptions_limit
      return unless user
      return if user.mobile_device_push_subscriptions.count < MAX_SUBSCRIPTIONS_PER_USER

      errors.add(:base, "cannot have more than #{MAX_SUBSCRIPTIONS_PER_USER} push subscriptions per user")
    end
  end
end
