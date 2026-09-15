# frozen_string_literal: true

require 'pact/consumer/rspec'
require_relative '../../helpers/pact_helper'
require_relative '../../helpers/contract_name_generator'
require_relative '../../fixtures/artifact_registry/index'
require_relative '../../resources/artifact_registry/repositories'

# Consumer spec for the Artifact Registry management API.
#
# Models the Rails monolith (gitlab-rails) as the consumer and the
# Artifact Registry service as the provider.
#
# pact-ruby generates the contract as <consumer>-<provider>.json by default.
# An at_exit hook renames it to follow the GitLab convention:
#   gitlab-rails-<service>-<resource>-<method>.json
#
# Contract is published to the gitlab-rails-consumer-contracts GCS bucket
# under artifact-registry/<gitlab-version>/.
# See doc/development/testing_guide/contract/ruby_consumer_tests.md for details.

# Constants are namespaced to avoid global constant pollution when multiple
# pact specs run in the same process.
module ArtifactRegistryIndexSpec
  CONSUMER_NAME = 'gitlab-rails'
  PROVIDER_NAME = 'artifact-registry'
  RESOURCE      = 'repositories'
  METHOD        = 'GET'
  CONTRACT_DIR  = PactHelper.contract_dir(__dir__)
end

Pact.configure do |config|
  config.pact_dir = ArtifactRegistryIndexSpec::CONTRACT_DIR
end

# pact-ruby has no DSL option to set a custom filename - it always writes
# <consumer>-<provider>.json. Use at_exit to rename after pact-ruby's own
# after(:suite) hook has finished writing the file.
#
# The contract file only exists if this spec's examples actually executed:
# the file may also be loaded in runs where the examples are filtered out by
# tags or nothing is executed at all (--dry-run), and then there is nothing
# to rename.
at_exit do
  this_file_examples_ran = !RSpec.configuration.dry_run? &&
    RSpec.world.example_groups.flat_map(&:descendants)
      .select { |group| group.metadata[:absolute_file_path] == __FILE__ }
      .any? { |group| RSpec.world.filtered_examples[group]&.any? }

  if !this_file_examples_ran
    puts "No examples ran, skipping contract file rename."
  else
    # pact-ruby lowercases both names when building the default filename
    default_path = File.join(
      ArtifactRegistryIndexSpec::CONTRACT_DIR,
      "#{ArtifactRegistryIndexSpec::CONSUMER_NAME}-#{ArtifactRegistryIndexSpec::PROVIDER_NAME.downcase}.json"
    )
    target_path = File.join(
      ArtifactRegistryIndexSpec::CONTRACT_DIR,
      ContractNameGenerator.generate(
        provider: ArtifactRegistryIndexSpec::PROVIDER_NAME,
        resource: ArtifactRegistryIndexSpec::RESOURCE,
        method: ArtifactRegistryIndexSpec::METHOD
      )
    )

    raise "Expected contract file not found at #{default_path}" unless File.exist?(default_path)

    File.rename(default_path, target_path)
  end
end

Pact.service_consumer ArtifactRegistryIndexSpec::CONSUMER_NAME do
  has_pact_with ArtifactRegistryIndexSpec::PROVIDER_NAME do
    mock_service(:artifact_registry_service) do
      host '127.0.0.1'
    end
  end
end

RSpec.describe "#{ArtifactRegistryIndexSpec::METHOD} /api/v1/:slug/#{ArtifactRegistryIndexSpec::RESOURCE}",
  :pact, feature_category: :artifact_registry do
  subject(:response) do
    ArtifactRegistry::Resources::Repositories.list(
      slug: 'my-namespace',
      base_url: artifact_registry_service.mock_service_base_url
    )
  end

  before do
    artifact_registry_service
      .given(ArtifactRegistry::Fixtures::Repositories::Index::PROVIDER_STATE)
      .upon_receiving(ArtifactRegistry::Fixtures::Repositories::Index::UPON_RECEIVING)
      .with(ArtifactRegistry::Fixtures::Repositories::Index::REQUEST)
      .will_respond_with(ArtifactRegistry::Fixtures::Repositories::Index::RESPONSE)
  end

  it 'returns a successful response with a list of repositories', :aggregate_failures do
    # rubocop:disable RSpec/HaveGitlabHttpStatus -- pact specs run outside Rails; have_gitlab_http_status is unavailable
    expect(response.status).to eq(200)
    # rubocop:enable RSpec/HaveGitlabHttpStatus

    # rubocop:disable Gitlab/Json -- pact specs run outside Rails; Gitlab::Json is unavailable
    body = JSON.parse(response.body)
    # rubocop:enable Gitlab/Json
    expect(body['repositories']).to be_an(Array)
    expect(body['repositories'].first).to include(
      'id', 'name', 'format', 'kind', 'visibility',
      'description', 'artifacts_count', 'downloads_count',
      'size_bytes', 'created_at'
    )
  end
end
