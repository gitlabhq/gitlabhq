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
      COMPOSITE_IDENTITY_SIDEKIQ_ARG = 'sqci' # Sidekiq Composite Identity

      IdentityError = Class.new(StandardError)
      IdentityLinkMismatchError = Class.new(IdentityError)
      UnexpectedIdentityError = Class.new(IdentityError)
      TooManyIdentitiesLinkedError = Class.new(IdentityError)
      MissingCompositeIdentityError = Class.new(::Gitlab::Access::AccessDeniedError)
      MissingServiceAccountError = Class.new(::Gitlab::Access::AccessDeniedError)

      # TODO: why is this called 3 times in doorkeeper_access_spec.rb specs?
      def self.link_from_oauth_token(oauth_token)
        fabricate(oauth_token.user).tap do |identity|
          identity.link!(oauth_token.scope_user) if identity&.composite?
        end
      end

      def self.link_from_job(job)
        fabricate(job.user).tap do |identity|
          identity.link!(job.scoped_user) if identity&.composite?
        end
      end

      def self.link_from_scoped_user_id(user, scoped_user_id)
        scoped_user = ::User.find_by_id(scoped_user_id)

        return unless scoped_user

        ::Gitlab::Auth::Identity.fabricate(user).tap do |identity|
          identity.link!(scoped_user) if identity&.composite?
        end
      end

      def self.link_from_web_request(service_account:, scoped_user:)
        raise MissingServiceAccountError, 'service account is required' unless service_account

        fabricate(service_account).tap do |identity|
          identity.link!(scoped_user) if identity&.composite?
        end
      end

      def self.sidekiq_restore!(job)
        ids = Array(job[COMPOSITE_IDENTITY_SIDEKIQ_ARG])

        return if ids.empty?
        raise IdentityError, 'unexpected number of identities in Sidekiq job' unless ids.size == 2

        ::Gitlab::Auth::Identity
          .new(::User.find(ids.first))
          .link!(::User.find(ids.second))
      end

      def self.currently_linked
        user = ::Gitlab::SafeRequestStore
          .store[COMPOSITE_IDENTITY_USERS_KEY]
          .to_a.first

        return unless user.present?

        identity = new(user)

        block_given? ? yield(identity) : identity
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
        @user.has_composite_identity?
      end

      def sidekiq_link!(job)
        job[COMPOSITE_IDENTITY_SIDEKIQ_ARG] = [primary_user_id, scoped_user_id]
      end

      def link!(scope_user)
        return self unless scope_user

        ##
        # TODO: consider extracting linking to ::Gitlab::Auth::Identities::Link#create!
        #
        validate_link!(scope_user)
        store_identity_link!(scope_user)
        append_log!(scope_user)

        self
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

      def primary_user
        @user
      end

      private

      def scoped_user_id
        scoped_user.id
      end

      def primary_user_id
        @user.id
      end

      def validate_link!(scope_user)
        return unless linked? && saved_scoped_user_different_from_new_scope_user?(scope_user)

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

      def append_log!(scope_user)
        ::Gitlab::ApplicationContext.push(scoped_user: scope_user)
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
