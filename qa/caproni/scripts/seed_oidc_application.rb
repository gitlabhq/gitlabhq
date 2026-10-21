#!/usr/bin/env ruby
# frozen_string_literal: true

# Shim, like seed_admin_token.rb: Caproni has no post-deploy hook, so register the
# consumer's OAuth client on the primary here, once its toolbox is up
# https://gitlab.com/gitlab-org/caproni/-/issues/192
#
# Runs on its own, or together with other seeders through scripts/seed.rb

module SeedOidcApplication
  APPLICATION_NAME = 'Caproni OIDC consumer'
  # openid, profile and email for the openid_connect provider, read_user for gitlab
  SCOPES = 'openid profile email read_user'
  PROVIDERS = %w[openid_connect gitlab].freeze

  module_function

  def description
    "the consumer's OAuth application"
  end

  # Doorkeeper takes several redirect URIs newline-separated
  def redirect_uri(consumer_url)
    PROVIDERS.map { |provider| "#{consumer_url}/users/auth/#{provider}/callback" }.join("\n")
  end

  # inspect escapes every value, so a quote in one cannot break out
  def seed_program(uid:, secret:, consumer_url:)
    <<~RUBY
      Gitlab::Seeder.quiet do
        if Authn::OauthApplication.exists?(uid: #{uid.inspect})
          puts 'OAuth application already exists, skipping'
        else
          Authn::OauthApplication.create!(
            name: #{APPLICATION_NAME.inspect},
            uid: #{uid.inspect},
            # Hashed on the way in, as Doorkeeper stores the secrets it generates itself
            secret: Authn::OauthApplication.encode(#{secret.inspect}),
            redirect_uri: #{redirect_uri(consumer_url).inspect},
            scopes: #{SCOPES.inspect},
            confidential: true,
            # Untrusted apps show an authorization screen the spec does not click through
            trusted: true,
            organization: Organizations::Organization.default_organization
          )
          puts 'OAuth application seeded'
        end
      end
    RUBY
  end

  def program_from_env
    uid = ENV.fetch('QA_OIDC_CLIENT_ID') { abort('QA_OIDC_CLIENT_ID is not set') }
    secret = ENV.fetch('QA_OIDC_CLIENT_SECRET') { abort('QA_OIDC_CLIENT_SECRET is not set') }
    consumer_url = ENV.fetch('QA_OIDC_CONSUMER_URL') { abort('QA_OIDC_CONSUMER_URL is not set') }

    seed_program(uid: uid, secret: secret, consumer_url: consumer_url)
  end
end

if __FILE__ == $PROGRAM_NAME
  # Here, not at the top: seed.rb loads this file, and must not load itself again
  require_relative 'seed'
  Seed.run([SeedOidcApplication])
end
