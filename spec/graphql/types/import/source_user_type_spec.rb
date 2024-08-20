# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ImportSourceUser'], feature_category: :importers do
  specify { expect(described_class.graphql_name).to eq('ImportSourceUser') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_import_source_user) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      importType
      placeholderUser
      reassignedByUser
      reassignToUser
      sourceHostname
      sourceName
      sourceUserIdentifier
      sourceUsername
      status
      reassignmentError
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
