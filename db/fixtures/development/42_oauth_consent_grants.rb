# frozen_string_literal: true

Gitlab::Seeder.quiet do
  organization = Group.not_mass_generated.first.organization

  grants = [
    { status: :authorized, source: :doorkeeper },
    { status: :revoked, source: :doorkeeper },
    { status: :authorized, source: :duo_session }
  ]

  users = User.not_mass_generated.where(organization_id: organization.id).first(grants.size)

  users.zip(grants).each do |user, attributes|
    name = "Consent grant seed for #{user.username}"

    next if Authn::OauthApplication.exists?(name: name, owner: user)

    application = Authn::OauthApplication.create!(
      name: name,
      redirect_uri: 'https://example.com/oauth/callback',
      scopes: 'api',
      owner: user,
      organization: organization
    )

    granular_scope = Authz::GranularScope.create!(
      organization: organization,
      access: :user,
      permissions: [:update_saved_reply]
    )

    grant = Authz::OauthConsentGrant.create!(user: user, application: application, **attributes)
    grant.oauth_consent_grant_granular_scopes.create!(granular_scope: granular_scope)
  rescue StandardError => e
    warn "\nError seeding OAuth consent grants for #{user.username}: #{e}"
  end
end
