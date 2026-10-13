#!/usr/bin/env ruby
# frozen_string_literal: true

# Shim, like seed_admin_token.rb: Caproni has no post-deploy hook, so register the
# consumer's OAuth client on the primary here, once its toolbox is up
# https://gitlab.com/gitlab-org/caproni/-/issues/192

require_relative 'seed_admin_token'

module SeedOidcApplication
  APPLICATION_NAME = 'Caproni OIDC consumer'
  # openid, profile and email for the openid_connect provider, read_user for gitlab
  SCOPES = 'openid profile email read_user'
  PROVIDERS = %w[openid_connect gitlab].freeze

  module_function

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

  def run
    uid = ENV.fetch('QA_OIDC_CLIENT_ID') { abort('QA_OIDC_CLIENT_ID is not set') }
    secret = ENV.fetch('QA_OIDC_CLIENT_SECRET') { abort('QA_OIDC_CLIENT_SECRET is not set') }
    consumer_url = ENV.fetch('QA_OIDC_CONSUMER_URL') { abort('QA_OIDC_CONSUMER_URL is not set') }
    # The primary's namespace: the application lives on the IdP, not the consumer
    namespace = ENV.fetch('NAMESPACE', 'gitlab')
    config = ENV.fetch('CAPRONI_CONFIG') { File.expand_path('../caproni.yaml', __dir__) }

    pod = SeedAdminToken.toolbox_pod(config, namespace)

    puts "Seeding the consumer's OAuth application via #{pod}"
    # stdin, not argv: keeps the secret out of the process list
    out, err, status = SeedAdminToken.caproni(config, namespace, 'exec', '-i', pod, '-c', 'toolbox', '--',
      'gitlab-rails', 'runner', '-',
      stdin_data: seed_program(uid: uid, secret: secret, consumer_url: consumer_url))

    unless status.success?
      # Last line only: no reason to widen what a failure prints
      warn 'Failed to seed the OAuth application'
      warn(err.lines.last || out.lines.last || 'no output')
      exit 1
    end

    puts out.strip unless out.strip.empty?
  end
end

SeedOidcApplication.run if __FILE__ == $PROGRAM_NAME
