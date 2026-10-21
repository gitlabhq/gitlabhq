#!/usr/bin/env ruby
# frozen_string_literal: true

# Shim: Caproni has no post-deploy hook, so seed the token here
# https://gitlab.com/gitlab-org/caproni/-/issues/192
#
# Runs on its own, or together with other seeders through scripts/seed.rb

module SeedAdminToken
  TOKEN_NAME = 'seeded-api-token'

  module_function

  def description
    'the admin personal access token'
  end

  # inspect escapes the token, so a quote in it cannot break out
  def seed_program(token)
    <<~RUBY
      Gitlab::Seeder.quiet do
        user = User.find_by!(username: 'root')

        if user.personal_access_tokens.exists?(name: #{TOKEN_NAME.inspect})
          puts 'Token already exists, skipping'
        else
          pat = user.personal_access_tokens.build(
            scopes: Gitlab::Auth.all_available_scopes.map(&:to_s),
            name: #{TOKEN_NAME.inspect}
          )
          pat.expires_at = 365.days.from_now
          pat.set_token(#{token.inspect})
          pat.organization = Organizations::Organization.default_organization
          pat.save!
          puts 'Admin personal access token seeded'
        end
      end
    RUBY
  end

  def program_from_env
    token = ENV.fetch('GITLAB_QA_ADMIN_ACCESS_TOKEN') do
      abort('GITLAB_QA_ADMIN_ACCESS_TOKEN is not set')
    end

    seed_program(token)
  end
end

if __FILE__ == $PROGRAM_NAME
  # Here, not at the top: seed.rb loads this file, and must not load itself again
  require_relative 'seed'
  Seed.run([SeedAdminToken])
end
