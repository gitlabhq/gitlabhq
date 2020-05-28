# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Query'] do
  it 'is called Query' do
    expect(described_class.graphql_name).to eq('Query')
  end

  it 'has the expected fields' do
    expected_fields = %i[
      current_user
      design_management
      geoNode
      group
      echo
      instanceSecurityDashboard
      metadata
      namespace
      project
      projects
      snippets
      user
      vulnerabilities
      vulnerabilitiesCountByDayAndSeverity
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
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
end
