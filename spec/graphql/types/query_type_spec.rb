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
      merge_request
      usage_trends_measurements
      runner_platforms
      runner
      runners
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

    it "finds an issue by it's gid" do
      is_expected.to have_graphql_arguments(:id)
      is_expected.to have_graphql_type(Types::IssueType)
    end
  end

  describe 'merge_request field' do
    subject { described_class.fields['mergeRequest'] }

    it "finds a merge_request by it's gid" do
      is_expected.to have_graphql_arguments(:id)
      is_expected.to have_graphql_type(Types::MergeRequestType)
    end
  end

  describe 'usage_trends_measurements field' do
    subject { described_class.fields['usageTrendsMeasurements'] }

    it 'returns usage trends measurements' do
      is_expected.to have_graphql_type(Types::Admin::Analytics::UsageTrends::MeasurementType.connection_type)
    end
  end

  describe 'runner field' do
    subject { described_class.fields['runner'] }

    it { is_expected.to have_graphql_type(Types::Ci::RunnerType) }
  end

  describe 'runners field' do
    subject { described_class.fields['runners'] }

    it { is_expected.to have_graphql_type(Types::Ci::RunnerType.connection_type) }
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

  describe 'package field' do
    subject { described_class.fields['package'] }

    it { is_expected.to have_graphql_type(Types::Packages::PackageDetailsType) }
  end
end
