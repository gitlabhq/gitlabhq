# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

# Create an api access token for root user with the value: ypCa3Dzb23o5nvsixwPA
Gitlab::Seeder.quiet do
  PersonalAccessToken.create!(
    user_id: User.find_by(username: 'root').id,
    name: "seeded-api-token",
    scopes: ["api"],
    token_digest: "/O0jfLERYT/L5gG8nfByQxqTj43TeLlRzOtJGTzRsbQ="
  )

  print '.'
end
