# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Identity class represents identity which we want to use in authorization policies.
    #
    # It decides if an identity is a single or composite identity and finds identity scope.
    #
    class Identity
      COMPOSITE_IDENTITY_USERS_KEY = 'composite_identities'
      COMPOSITE_IDENTITY_KEY_FORMAT = 'user:%s:composite_identity'

      IdentityError = Class.new(StandardError)
      IdentityLinkMismatchError = Class.new(IdentityError)
      UnexpectedIdentityError = Class.new(IdentityError)
      TooManyIdentitiesLinkedError = Class.new(IdentityError)
      MissingCompositeIdentityError = Class.new(::Gitlab::Access::AccessDeniedError)

      # TODO: why is this called 3 times in doorkeeper_access_spec.rb specs?
      def self.link_from_oauth_token(oauth_token)
        fabricate(oauth_token.user).tap do |identity|
          identity.link!(oauth_token.scope_user) if identity&.composite?
        end
      end

      def self.fabricate(user)
        new(user) if user.is_a?(::User)
      end

      def initialize(user, store: ::Gitlab::SafeRequestStore)
        raise UnexpectedIdentityError unless user.is_a?(::User)

        @user = user
        @request_store = store
      end

      def composite?
        return false unless Feature.enabled?(:composite_identity, @user)

        @user.has_composite_identity?
      end

      def linked?
        @request_store.exist?(store_key)
      end

      def valid?
        return true unless composite?

        linked?
      end

      def scoped_user
        @request_store.fetch(store_key) do
          raise MissingCompositeIdentityError, 'composite identity missing'
        end
      end

      def link!(scope_user)
        return unless scope_user

        validate_link!(scope_user)
        store_identity_link!(scope_user)

        self
      end

      private

      def scoped_user_id
        scoped_user.id
      end

      def scoped_user_present?
        @request_store.exist?(store_key)
      end

      def validate_link!(scope_user)
        return unless scoped_user_present? && saved_scoped_user_different_from_new_scope_user?(scope_user)

        raise IdentityLinkMismatchError, 'identity link change detected'
      end

      def saved_scoped_user_different_from_new_scope_user?(scope_user)
        scoped_user_id != scope_user.id
      end

      def store_identity_link!(scope_user)
        @request_store.store[store_key] = scope_user

        composite_identities.add(@user)

        raise TooManyIdentitiesLinkedError if composite_identities.size > 1
      end

      def composite_identities
        @request_store.store[COMPOSITE_IDENTITY_USERS_KEY] ||= Set.new
      end

      def store_key
        @store_key ||= format(COMPOSITE_IDENTITY_KEY_FORMAT, @user.id)
      end
    end
  end
end
