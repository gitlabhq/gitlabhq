# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Query'] do
  it 'is called Query' do
    expect(described_class.graphql_name).to eq('Query')
  end

  it { is_expected.to have_graphql_fields(:project, :namespace, :group, :echo, :metadata, :current_user, :snippets) }

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
end
