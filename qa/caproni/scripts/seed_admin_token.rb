#!/usr/bin/env ruby
# frozen_string_literal: true

# Shim: Caproni has no post-deploy hook, so seed the token here
# https://gitlab.com/gitlab-org/caproni/-/issues/192

require 'open3'

module SeedAdminToken
  TOKEN_NAME = 'seeded-api-token'

  module_function

  # Array form throughout: no shell, so nothing here needs quoting or escaping.
  def caproni(config, namespace, *args, **opts)
    Open3.capture3('caproni', '-c', config, 'kubectl', '-n', namespace, *args, **opts)
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

  def toolbox_pod(config, namespace)
    puts 'Waiting for the toolbox pod'
    _, err, status = caproni(config, namespace, 'wait', '--for=condition=Ready', 'pods',
      '--selector=app=toolbox', '--timeout=300s')
    abort("Toolbox pod never became ready: #{err.lines.last}") unless status.success?

    pod, err, status = caproni(config, namespace, 'get', 'pods', '--selector=app=toolbox',
      '-o', 'jsonpath={.items[0].metadata.name}')
    abort("Could not find the toolbox pod: #{err.lines.last}") unless status.success?
    abort('Could not find the toolbox pod: no pods matched app=toolbox') if pod.strip.empty?

    pod.strip
  end

  def run
    token = ENV.fetch('GITLAB_QA_ADMIN_ACCESS_TOKEN') do
      abort('GITLAB_QA_ADMIN_ACCESS_TOKEN is not set')
    end
    namespace = ENV.fetch('NAMESPACE', 'gitlab')
    # From this script's location, so cwd does not matter
    config = ENV.fetch('CAPRONI_CONFIG') { File.expand_path('../caproni.yaml', __dir__) }

    pod = toolbox_pod(config, namespace)

    puts "Seeding admin personal access token via #{pod}"
    # stdin, not argv: keeps the token out of the process list
    out, err, status = caproni(config, namespace, 'exec', '-i', pod, '-c', 'toolbox', '--',
      'gitlab-rails', 'runner', '-', stdin_data: seed_program(token))

    unless status.success?
      # Last line only: no reason to widen what a failure prints
      warn 'Failed to seed admin token'
      warn(err.lines.last || out.lines.last || 'no output')
      exit 1
    end

    puts out.strip unless out.strip.empty?
  end
end

SeedAdminToken.run if __FILE__ == $PROGRAM_NAME
