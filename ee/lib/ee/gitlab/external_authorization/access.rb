module EE
  module Gitlab
    module ExternalAuthorization
      class Access
        attr_reader :access, :reason, :loaded_at

        def initialize(user, label)
          @user, @label = user, label
        end

        def loaded?
          loaded_at && (loaded_at > Cache::VALIDITY_TIME.ago)
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
          @access, @reason, @loaded_at = cache.load
        end

        def load_from_service
          response = Client.new(@user, @label).request_access
          @access = response.successful?
          @reason = response.reason
          @loaded_at = Time.now
          cache.store(@access, @reason, @loaded_at) if response.valid?
        rescue EE::Gitlab::ExternalAuthorization::RequestFailed => e
          @access = false
          @reason = e.message
          @loaded_at = Time.now
        end

        def cache
          @cache ||= Cache.new(@user, @label)
        end
      end
    end
  end
end
