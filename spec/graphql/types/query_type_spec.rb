# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Query'], feature_category: :shared do
  include GraphqlHelpers

  include_context 'with FOSS query type fields'

  it 'is called Query' do
    expect(described_class.graphql_name).to eq('Query')
  end

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(*expected_foss_fields).at_least
  end

  describe 'current_user field' do
    subject { described_class.fields['currentUser'] }

    it 'returns current user' do
      is_expected.to have_graphql_type(Types::CurrentUserType)
    end
  end

  describe 'namespace field' do
    subject { described_class.fields['namespace'] }

    it 'finds namespaces by full path' do
      is_expected.to have_graphql_arguments(:full_path)
      is_expected.to have_graphql_type(Types::NamespaceType)
      is_expected.to have_graphql_resolver(Resolvers::NamespaceResolver)
    end
  end

  describe 'organization field' do
    subject { described_class.fields['organization'] }

    it 'finds organization by path' do
      is_expected.to have_graphql_arguments(:id)
      is_expected.to have_graphql_type(Types::Organizations::OrganizationType)
      is_expected.to have_graphql_resolver(Resolvers::Organizations::OrganizationResolver)
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
      is_expected.to have_graphql_type(Types::AppConfig::InstanceMetadataType)
      is_expected.to have_graphql_resolver(Resolvers::AppConfig::InstanceMetadataResolver)
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

    it { is_expected.to have_graphql_type(Types::ContainerRegistry::ContainerRepositoryDetailsType) }
  end

  describe 'package field' do
    subject { described_class.fields['package'] }

    it { is_expected.to have_graphql_type(Types::Packages::PackageDetailsType) }
  end

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'returns timelogs' do
      is_expected.to have_graphql_arguments(:startDate, :endDate, :startTime, :endTime, :username, :projectId, :groupId, :after, :before, :first, :last, :sort)
      is_expected.to have_graphql_type(Types::TimelogType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
    end
  end

  describe 'boardList field' do
    subject { described_class.fields['boardList'] }

    it 'finds a board list by its gid' do
      is_expected.to have_graphql_arguments(:id, :issue_filters)
      is_expected.to have_graphql_type(Types::BoardListType)
      is_expected.to have_graphql_resolver(Resolvers::BoardListResolver)
    end
  end

  describe 'mlModel field' do
    subject { described_class.fields['mlModel'] }

    it 'returns metadata', :aggregate_failures do
      is_expected.to have_graphql_type(Types::Ml::ModelType)
      is_expected.to have_graphql_arguments(:id)
      is_expected.to have_graphql_resolver(Resolvers::Ml::ModelDetailResolver)
    end
  end

  describe 'integration_exclusions field' do
    subject { described_class.fields['integrationExclusions'] }

    it 'returns metadata', :aggregate_failures do
      is_expected.to have_graphql_arguments(:integrationName)
      is_expected.to have_graphql_type(Types::Integrations::ExclusionType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::Integrations::ExclusionsResolver)
    end
  end

  describe 'featureFlagEnabled field' do
    subject { described_class.fields['featureFlagEnabled'] }

    it 'returns feature flag status', :aggregate_failures do
      is_expected.to have_graphql_type(GraphQL::Types::Boolean.to_non_null_type)
      is_expected.to have_graphql_arguments(:name)
      is_expected.to have_graphql_resolver(Resolvers::FeatureFlagResolver)
    end
  end
end
