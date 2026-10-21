#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs the programs of the given seeders on the primary in one `gitlab-rails runner`.
# Each runner boots Rails in the toolbox pod, which takes about a minute, so a job
# that needs several seeders lists them all in one call:
#
#   scripts/seed.rb admin_token oidc_application
#
# Shim: Caproni has no post-deploy hook, so seed here
# https://gitlab.com/gitlab-org/caproni/-/issues/192

require 'open3'

module Seed
  module_function

  # Array form throughout: no shell, so nothing here needs quoting or escaping.
  def caproni(config, namespace, *args, **opts)
    Open3.capture3('caproni', '-c', config, 'kubectl', '-n', namespace, *args, **opts)
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

  def program(seeders)
    seeders.map(&:program_from_env).join
  end

  def run(seeders)
    # Built first, so a missing variable aborts before waiting for the pod
    stdin = program(seeders)
    description = seeders.map(&:description).join(' and ')
    # The primary's namespace: everything seeded here lives on the instance under test
    namespace = ENV.fetch('NAMESPACE', 'gitlab')
    # From this script's location, so cwd does not matter
    config = ENV.fetch('CAPRONI_CONFIG') { File.expand_path('../caproni.yaml', __dir__) }

    pod = toolbox_pod(config, namespace)

    puts "Seeding #{description} via #{pod}"
    # stdin, not argv: keeps tokens and secrets out of the process list
    out, err, status = caproni(config, namespace, 'exec', '-i', pod, '-c', 'toolbox', '--',
      'gitlab-rails', 'runner', '-', stdin_data: stdin)

    unless status.success?
      # Last line only: no reason to widen what a failure prints
      warn "Failed to seed #{description}"
      warn(err.lines.last || out.lines.last || 'no output')
      exit 1
    end

    puts out.strip unless out.strip.empty?
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative 'seed_admin_token'
  require_relative 'seed_oidc_application'

  seeders = { 'admin_token' => SeedAdminToken, 'oidc_application' => SeedOidcApplication }
  usage = "Usage: #{$PROGRAM_NAME} #{seeders.keys.join('|')}..."
  abort(usage) if ARGV.empty?

  Seed.run(ARGV.map { |name| seeders.fetch(name) { abort("Unknown seeder #{name}. #{usage}") } })
end
