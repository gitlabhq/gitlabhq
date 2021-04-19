# frozen_string_literal: true

module Gitlab
  module ExternalAuthorization
    class Access
      attr_reader :user,
                  :reason,
                  :loaded_at,
                  :label,
                  :load_type

      def initialize(user, label)
        @user = user
        @label = label
      end

      def loaded?
        loaded_at && (loaded_at > ExternalAuthorization::Cache::VALIDITY_TIME.ago)
      end

      def has_access?
        @access
      end

      def load!
        load_from_cache
        load_from_service unless loaded?
        self
      end

      private

      def load_from_cache
        @load_type = :cache
        @access, @reason, @loaded_at = cache.load
      end

      def load_from_service
        @load_type = :request
        response = Client.new(@user, @label).request_access
        @access = response.successful?
        @reason = response.reason
        @loaded_at = Time.now
        cache.store(@access, @reason, @loaded_at) if response.valid?
      rescue ::Gitlab::ExternalAuthorization::RequestFailed => e
        @access = false
        @reason = e.message
        @loaded_at = Time.now
      end

      def cache
        @cache ||= ExternalAuthorization::Cache.new(@user, @label)
      end
    end
  end
end
