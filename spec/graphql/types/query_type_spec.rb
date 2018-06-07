require 'spec_helper'

describe GitlabSchema.types['Query'] do
  it 'is called Query' do
    expect(described_class.graphql_name).to eq('Query')
  end

  it { is_expected.to have_graphql_fields(:project, :merge_request, :echo) }

  describe 'project field' do
    subject { described_class.fields['project'] }

    it 'finds projects by full path' do
      is_expected.to have_graphql_arguments(:full_path)
      is_expected.to have_graphql_type(Types::ProjectType)
      is_expected.to have_graphql_resolver(Resolvers::ProjectResolver)
    end

    it 'authorizes with read_project' do
      is_expected.to require_graphql_authorizations(:read_project)
    end
  end

  describe 'merge_request field' do
    subject { described_class.fields['mergeRequest'] }

    it 'finds MRs by project and IID' do
      is_expected.to have_graphql_arguments(:full_path, :iid)
      is_expected.to have_graphql_type(Types::MergeRequestType)
      is_expected.to have_graphql_resolver(Resolvers::MergeRequestResolver)
    end

    it 'authorizes with read_merge_request' do
      is_expected.to require_graphql_authorizations(:read_merge_request)
    end
  end
end
