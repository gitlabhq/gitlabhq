#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates caproni.local.yaml: the CI domain, plus the opt-in fragments a job extends
# An overlay, not the base config: the base config wins over the environment

require 'yaml'

module WriteLocalConfig
  module_function

  # Deployment variation lives in the fragments, so this only has to pick them
  def build(domain:, relative_url_root: nil, qa_scenario: nil)
    fragments = []
    fragments << 'caproni.github-oauth.yaml' if qa_scenario == 'Test::Integration::OAuth'
    fragments << 'caproni.relative-url.yaml' unless relative_url_root.to_s.empty?

    config = { 'variables' => { 'BASE_DOMAIN' => domain } }
    config['extends'] = fragments unless fragments.empty?

    config
  end

  def run
    domain = ENV.fetch('GITLAB_DOMAIN') { abort('GITLAB_DOMAIN is not set') }
    # A failed host lookup leaves ".nip.io", which deploys then times out
    abort("GITLAB_DOMAIN is not a full domain: #{domain.inspect}") if domain.start_with?('.')
    path = ENV.fetch('CAPRONI_LOCAL_CONFIG') { File.expand_path('../caproni.local.yaml', __dir__) }

    yaml = build(
      domain: domain,
      relative_url_root: ENV['QA_RELATIVE_URL_ROOT'],
      qa_scenario: ENV['QA_SCENARIO']
    ).to_yaml
    File.write(path, yaml)

    puts "Wrote #{path}"
    puts yaml
  end
end

WriteLocalConfig.run if __FILE__ == $PROGRAM_NAME
