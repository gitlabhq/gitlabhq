# frozen_string_literal: true

# Create an api access token for root user with the value:
token = 'ypCa3Dzb23o5nvsixwPA'
scopes = Gitlab::Auth.all_available_scopes

Gitlab::Seeder.quiet do
  User.find_by(username: 'root').tap do |user|
    params = {
      scopes: scopes.map(&:to_s),
      name: 'seeded-api-token'
    }

    user.personal_access_tokens.build(params).tap do |pat|
      pat.expires_at = 365.days.from_now
      pat.set_token(token)
      pat.organization = Organizations::Organization.default_organization
      pat.save!
    end
  end

  print '.'
end
