Doorkeeper::OpenidConnect.configure do
  issuer Gitlab.config.gitlab.url

  signing_key Rails.application.secrets.openid_connect_signing_key

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
    # hash the user's ID with the Rails secret_key_base to avoid revealing it
    Digest::SHA256.hexdigest "#{user.id}-#{Rails.application.secrets.secret_key_base}"
  end

  claims do
    with_options scope: :openid do |o|
      o.claim(:name)           { |user| user.name }
      o.claim(:nickname)       { |user| user.username }
      o.claim(:email)          { |user| user.public_email  }
      o.claim(:email_verified) { |user| true if user.public_email? }
      o.claim(:website)        { |user| user.full_website_url if user.website_url? }
      o.claim(:profile)        { |user| Gitlab::Routing.url_helpers.user_url user }
      o.claim(:picture)        { |user| user.avatar_url(only_path: false) }
      o.claim(:groups)         { |user| user.membership_groups.map(&:full_path) }
    end
  end
end
