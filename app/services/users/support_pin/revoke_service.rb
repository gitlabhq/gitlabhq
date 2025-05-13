# frozen_string_literal: true

module Users
  module SupportPin
    class RevokeService < SupportPin::BaseService
      def execute
        return { status: :not_found, message: 'Support PIN not found or already expired' } unless pin_exists?

        revoked = revoke_pin

        if revoked
          { status: :success }
        else
          { status: :error, message: 'Failed to revoke support PIN' }
        end
      end

      private

      def revoke_pin
        Gitlab::Redis::Cache.with do |redis|
          key = pin_key
          redis.expire(key, 0) # Set to expire immediately
        end
      end
    end
  end
end
