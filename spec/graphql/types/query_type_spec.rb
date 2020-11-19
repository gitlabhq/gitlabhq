# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Query'] do
  it 'is called Query' do
    expect(described_class.graphql_name).to eq('Query')
  end

  it 'has the expected fields' do
    expected_fields = %i[
      project
      namespace
      group
      echo
      metadata
      current_user
      snippets
      design_management
      milestone
      user
      users
      issue
      instance_statistics_measurements
      runner_platforms
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end

  describe 'namespace field' do
    subject { described_class.fields['namespace'] }

    it 'finds namespaces by full path' do
      is_expected.to have_graphql_arguments(:full_path)
      is_expected.to have_graphql_type(Types::NamespaceType)
      is_expected.to have_graphql_resolver(Resolvers::NamespaceResolver)
    end
  end

  describe 'project field' do
    subject { described_class.fields['project'] }

    it 'finds projects by full path' do
      is_expected.to have_graphql_arguments(:full_path)
      is_expected.to have_graphql_type(Types::ProjectType)
      is_expected.to have_graphql_resolver(Resolvers::ProjectResolver)
    end
  end

  describe 'metadata field' do
    subject { described_class.fields['metadata'] }

    it 'returns metadata' do
      is_expected.to have_graphql_type(Types::MetadataType)
      is_expected.to have_graphql_resolver(Resolvers::MetadataResolver)
    end
  end

  describe 'issue field' do
    subject { described_class.fields['issue'] }

    it 'returns issue' do
      is_expected.to have_graphql_type(Types::IssueType)
    end
  end

  describe 'instance_statistics_measurements field' do
    subject { described_class.fields['instanceStatisticsMeasurements'] }

    it 'returns instance statistics measurements' do
      is_expected.to have_graphql_type(Types::Admin::Analytics::InstanceStatistics::MeasurementType.connection_type)
    end
  end

  describe 'runner_platforms field' do
    subject { described_class.fields['runnerPlatforms'] }

    it 'returns runner platforms' do
      is_expected.to have_graphql_type(Types::Ci::RunnerPlatformType.connection_type)
    end
  end

  describe 'runner_setup field' do
    subject { described_class.fields['runnerSetup'] }

    it 'returns runner setup instructions' do
      is_expected.to have_graphql_type(Types::Ci::RunnerSetupType)
    end
  end

  describe 'container_repository field' do
    subject { described_class.fields['containerRepository'] }

    it { is_expected.to have_graphql_type(Types::ContainerRepositoryDetailsType) }
  end
end
