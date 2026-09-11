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
      AUTHENTICATED_IDENTITY_KEY = 'authenticated_composite_identity'
      LAST_LINKED_IDENTITY_KEY = 'last_linked_composite_identity'
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
          identity.link!(oauth_token.scope_user, context: :authentication) if identity&.composite?
        end
      end

      def self.link_from_job(job)
        fabricate(job.user).tap do |identity|
          identity.link!(job.scoped_user, context: :authentication) if identity&.composite?
        end
      end

      def self.link_from_scoped_user_id(user, scoped_user_id, context: :permission_check)
        scoped_user = ::User.find_by_id(scoped_user_id)

        return unless scoped_user

        ::Gitlab::Auth::Identity.link_from_scoped_user(user, scoped_user, context: context)
      end

      def self.link_from_scoped_user(user, scoped_user, context: :permission_check)
        ::Gitlab::Auth::Identity.fabricate(user).tap do |identity|
          identity.link!(scoped_user, context: context) if identity&.composite?
        end
      end

      def self.link_from_web_request(service_account:, scoped_user:)
        raise MissingServiceAccountError, 'service account is required' unless service_account

        fabricate(service_account).tap do |identity|
          identity.link!(scoped_user, context: :permission_check) if identity&.composite?
        end
      end

      def self.sidekiq_restore!(job)
        args = Array(job[COMPOSITE_IDENTITY_SIDEKIQ_ARG])

        return if args.empty?
        raise IdentityError, 'unexpected number of identities in Sidekiq job' unless args.size.in?([2, 3])

        context = args[2]&.to_sym || :authentication

        ::Gitlab::Auth::Identity
          .new(::User.find(args.first))
          .link!(::User.find(args.second), context: context)
      end

      def self.currently_linked
        users = ::Gitlab::SafeRequestStore.store[COMPOSITE_IDENTITY_USERS_KEY].to_a
        user = preferred_primary_user(users)

        return unless user.present?

        identity = new(user)

        block_given? ? yield(identity) : identity
      end

      def self.fabricate(user)
        new(user) if user.is_a?(::User)
      end

      def self.find_primary_user_by_scoped_user_id(scoped_user_id, store: ::Gitlab::SafeRequestStore)
        return unless scoped_user_id

        # Get all composite identities from the store
        composite_identities = store.store[COMPOSITE_IDENTITY_USERS_KEY] || Set.new

        # Check each composite identity to find the ones with matching scoped user
        matching = composite_identities.select do |primary_user|
          identity_key = format(COMPOSITE_IDENTITY_KEY_FORMAT, primary_user.id)
          link_data = store.store[identity_key]

          scoped_user = link_data.is_a?(Hash) ? link_data[:user] : link_data

          scoped_user&.id == scoped_user_id
        end

        preferred_primary_user(matching, store: store)
      end

      def self.resolve_composite_identity_actor(current_user)
        return unless current_user

        primary_user = Gitlab::Auth::Identity.find_primary_user_by_scoped_user_id(current_user.id)
        return current_user unless primary_user

        if new(primary_user).link_context == :authentication
          primary_user
        else
          current_user
        end
      end

      def self.preferred_primary_user(users, store: ::Gitlab::SafeRequestStore)
        authenticated_primary_user(users, store: store) ||
          last_linked_primary_user(users, store: store) ||
          users.first
      end
      private_class_method :preferred_primary_user

      def self.authenticated_primary_user(users, store: ::Gitlab::SafeRequestStore)
        authenticated_id = store.store[AUTHENTICATED_IDENTITY_KEY]
        return unless authenticated_id

        users.find { |user| user.id == authenticated_id }
      end
      private_class_method :authenticated_primary_user

      def self.last_linked_primary_user(users, store: ::Gitlab::SafeRequestStore)
        last_linked_id = store.store[LAST_LINKED_IDENTITY_KEY]
        return unless last_linked_id

        users.find { |user| user.id == last_linked_id }
      end
      private_class_method :last_linked_primary_user

      def initialize(user, store: ::Gitlab::SafeRequestStore)
        raise UnexpectedIdentityError unless user.is_a?(::User)

        @user = user
        @request_store = store
      end

      def composite?
        @user.composite_identity_enforced?
      end

      def sidekiq_link!(job)
        job[COMPOSITE_IDENTITY_SIDEKIQ_ARG] = [primary_user_id, scoped_user_id, link_context]
      end

      def link!(scope_user, context: :authentication)
        return self unless scope_user

        ##
        # TODO: consider extracting linking to ::Gitlab::Auth::Identities::Link#create!
        #
        validate_link!(scope_user)

        return self if linked? && link_context == :authentication && context == :permission_check

        store_identity_link!(scope_user, context: context)
        append_log!(scope_user)

        self
      end

      def linked?
        @request_store.exist?(store_key)
      end

      def valid?
        return true unless composite?

        return false unless linked?

        !scoped_user.composite_identity_enforced?
      end

      def scoped_user
        link_data = @request_store.fetch(store_key) do
          raise MissingCompositeIdentityError, 'composite identity missing'
        end

        user_from_link_data(link_data)
      end

      def link_context
        link_data = @request_store[store_key]
        return unless link_data

        link_data.is_a?(Hash) ? link_data[:context] : :authentication
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

      def store_identity_link!(scope_user, context: :authentication)
        claim_authenticated_identity! if context == :authentication

        @request_store.store[store_key] = { user: scope_user, context: context }
        @request_store.store[LAST_LINKED_IDENTITY_KEY] = @user.id

        composite_identities.add(@user)
      end

      def claim_authenticated_identity!
        claimed_id = @request_store.store[AUTHENTICATED_IDENTITY_KEY]

        if claimed_id && claimed_id != @user.id
          raise TooManyIdentitiesLinkedError,
            "user #{@user.id} cannot be linked: user #{claimed_id} is already the authenticated identity"
        end

        @request_store.store[AUTHENTICATED_IDENTITY_KEY] = @user.id
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

      def user_from_link_data(link_data)
        link_data.is_a?(Hash) ? link_data[:user] : link_data
      end
    end
  end
end
