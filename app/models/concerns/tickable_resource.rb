# frozen_string_literal: true

module TickableResource
  extend ActiveSupport::Concern

  class_methods do
    def tickable_resource_fields
      @tickable_resource_fields || []
    end

    private # rubocop:disable Lint/UselessAccessModifier

    def add_tickable_resource(field, expire:, notification_channel: Gitlab::Workhorse::NOTIFICATION_CHANNEL, &blk)
      @tickable_resource_fields = [] unless @tickable_resource_fields
      @tickable_resource_fields << field

      define_method("#{field}_key") do
        blk.call(self)
      end

      define_method("tick_#{field}") do
        SecureRandom.hex.tap do |new_update|
          ::Gitlab::Workhorse.set_key_and_notify(
            public_send("#{field}_key"), new_update,
            notification_channel: notification_channel,
            expire: expire, overwrite: true)
        end
      end

      define_method("ensure_#{field}_value") do
        new_value = SecureRandom.hex
        ::Gitlab::Workhorse.set_key_and_notify(
          public_send("#{field}_key"), new_value,
          notification_channel: notification_channel,
          expire: expire, overwrite: false)
      end

      define_method("clear_#{field}") do
        Gitlab::Redis::Queues.with do |redis|
          redis.del(public_send("#{field}_key"))
        end
      end

      define_method("#{field}_value_latest?") do |value|
        public_send("ensure_#{field}_value") == value if value.present?
      end
    end
  end
end
