# frozen_string_literal: true

# Generates Pact contract filenames following the GitLab convention:
#
#   gitlab-rails-<service>-<resource>-<method>.json
#
# All segments are lowercased for consistency with the Ruby style guide
# and pact-ruby's own default filename behaviour.
#
# Usage:
#   ContractNameGenerator.generate(
#     provider: 'artifact-registry',
#     resource: 'repositories',
#     method:   'GET'
#   )
#   # => 'gitlab-rails-artifact-registry-repositories-get.json'
module ContractNameGenerator
  CONSUMER = 'gitlab-rails'

  # @param provider [String] the provider/service name (e.g. 'artifact-registry')
  # @param resource [String] the resource name (e.g. 'repositories')
  # @param method   [String] the HTTP method (e.g. 'GET', 'get')
  # @return [String] e.g. 'gitlab-rails-artifact-registry-repositories-get.json'
  def self.generate(provider:, resource:, method:)
    "#{CONSUMER}-#{provider.downcase}-#{resource.downcase}-#{method.downcase}.json"
  end
end
