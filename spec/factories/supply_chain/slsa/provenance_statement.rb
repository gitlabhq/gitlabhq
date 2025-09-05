# frozen_string_literal: true

# https://slsa.dev/spec/v1.1/provenance
FactoryBot.define do
  factory :provenance_statement, class: 'SupplyChain::Slsa::ProvenanceStatement' do
    _type { "https://in-toto.io/Statement/v1" }
    subject { [association(:resource_descriptor), association(:resource_descriptor)] }
    predicate_type { "https://slsa.dev/provenance/v1" }
    predicate { association(:predicate) }

    skip_create
  end

  factory :predicate, class: 'SupplyChain::Slsa::ProvenanceStatement::Predicate' do
    build_definition { association(:build_definition) }
    run_details { association(:run_details) }

    skip_create
  end

  factory :resource_descriptor, class: 'SupplyChain::Slsa::ResourceDescriptor' do
    sequence(:name) { |n| "resource_#{n}" }
    sequence(:digest) do |n|
      {
        sha256: Digest::SHA256.hexdigest("resource_#{n}")
      }
    end

    skip_create
  end

  factory :build_definition, class: 'SupplyChain::Slsa::ProvenanceStatement::BuildDefinition' do
    build_type { "https://gitlab.com/gitlab-org/gitlab-runner/-/blob/15/PROVENANCE.md" }

    # Arbitrary JSON object according to spec.
    external_parameters do
      {
        repository: "https://gitlab.com/tanuki/hello-world",
        ref: "refs/heads/main",
        variables: { CI_PIPELINE: "test", ANOTHER_UPPERCASED_VAR: "test" }
      }
    end

    # Arbitrary JSON object according to spec.
    internal_parameters do
      {
        doc_ref: "https://gitlab.com/tanuki/hello-world",
        ref_ref: "refs/heads/main"
      }
    end

    resolved_dependencies do
      [association(:resource_descriptor), association(:resource_descriptor), association(:resource_descriptor)]
    end

    skip_create
  end

  factory :run_details, class: 'SupplyChain::Slsa::ProvenanceStatement::RunDetails' do
    builder { association(:builder) }
    metadata { association(:build_metadata) }
    byproducts { [association(:resource_descriptor)] }

    skip_create
  end
  factory :build_metadata, class: 'SupplyChain::Slsa::ProvenanceStatement::BuildMetadata' do
    sequence(:invocation_id) { |nb| "build_#{nb}" }
    started_on { "2025-06-09T08:48:14Z" }
    finished_on { "2025-06-10T08:48:14Z" }

    skip_create
  end

  factory :builder, class: 'SupplyChain::Slsa::ProvenanceStatement::Builder' do
    id { "https://gitlab.com/gitlab-org/gitlab-runner/-/blob/15/RUN_TYPE.md" }
    builder_dependencies { [association(:resource_descriptor)] }
    version { { "gitlab-runner": "4d7093e1" } }

    skip_create
  end
end
