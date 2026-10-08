# frozen_string_literal: true

Gitlab::Seeder.quiet do
  organization = Group.not_mass_generated.first.organization
  owner = User.not_mass_generated.where(organization_id: organization.id).first
  name = "Granular scope seed for #{owner.username}"

  next if Authn::OauthApplication.exists?(name: name, owner: owner)

  application = Authn::OauthApplication.create!(
    name: name,
    redirect_uri: 'https://example.com/oauth/callback',
    scopes: 'api',
    owner: owner,
    organization: organization
  )

  granular_scope = Authz::GranularScope.create!(
    organization: organization,
    access: :user,
    permissions: [:update_saved_reply]
  )

  application.oauth_application_granular_scopes.create!(granular_scope: granular_scope)
rescue StandardError => e
  warn "\nError seeding OAuth application granular scopes: #{e}"
end
