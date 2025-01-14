# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer Gitlab.config.gitlab.url

  signing_key Rails.application.credentials.openid_connect_signing_key

  resource_owner_from_access_token do |access_token|
    User.active.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |user|
    user.current_sign_in_at
  end

  reauthenticate_resource_owner do |user, return_to|
    store_location_for user, return_to
    sign_out user
    redirect_to new_user_session_url
  end

  subject do |user|
    user.id
  end

  expiration Gitlab.config.oidc_provider.openid_id_token_expire_in_seconds

  claims do
    with_options scope: :openid do |o|
      o.claim(:sub_legacy, response: [:id_token, :user_info]) do |user|
        # provide the previously hashed 'sub' claim to allow third-party apps
        # to migrate to the new unhashed value
        Digest::SHA256.hexdigest "#{user.id}-#{Rails.application.credentials.secret_key_base}"
      end

      o.claim(:name, response: [:id_token, :user_info]) { |user| user.name }
      o.claim(:nickname, response: [:id_token, :user_info]) { |user| user.username }
      o.claim(:preferred_username, response: [:id_token, :user_info]) { |user| user.username }

      # Check whether the application has access to the email scope, and grant
      # access to the user's primary email address if so, otherwise their
      # public email address (if present)
      # This allows existing solutions built for GitLab's old behavior to keep
      # working without modification.
      o.claim(:email, response: [:id_token, :user_info]) do |user, scopes|
        scopes.exists?(:email) ? user.email : user.public_email
      end
      o.claim(:email_verified, response: [:id_token, :user_info]) do |user, scopes|
        if scopes.exists?(:email)
          user.primary_email_verified?
        elsif user.public_email?
          user.verified_email?(user.public_email)
        else
          # If there is no public email set, tell doorkicker-openid-connect to
          # exclude the email_verified claim by returning nil.
          nil
        end
      end

      o.claim(:website, response: [:id_token, :user_info]) do |user|
        user.full_website_url if user.website_url.present?
      end
      o.claim(:profile, response: [:id_token, :user_info]) { |user| Gitlab::Routing.url_helpers.user_url user }
      o.claim(:picture, response: [:id_token, :user_info]) { |user| user.avatar_url(only_path: false) }
      o.claim(:groups) do |user|
        user.membership_groups.joins(:route).with_route
          .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
          .map(&:full_path)
      end
      o.claim(:groups_direct, response: [:id_token]) do |user|
        user.groups.joins(:route).with_route
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
        .map(&:full_path)
      end
      o.claim('https://gitlab.org/claims/groups/owner') do |user|
        user.owned_groups.joins(:route).with_route
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
        .map(&:full_path).presence
      end
      o.claim('https://gitlab.org/claims/groups/maintainer') do |user|
        user.maintainers_groups.joins(:route).with_route
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
        .map(&:full_path).presence
      end
      o.claim('https://gitlab.org/claims/groups/developer') do |user|
        user.developer_groups.joins(:route).with_route
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046")
        .map(&:full_path).presence
      end
    end
  end
end
