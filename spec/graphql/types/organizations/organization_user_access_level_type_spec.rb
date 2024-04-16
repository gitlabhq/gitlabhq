# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationUserAccess'], feature_category: :cell do
  specify { expect(described_class.graphql_name).to eq('OrganizationUserAccess') }
  specify { expect(described_class).to require_graphql_authorizations(nil) }

  it 'has expected fields' do
    expected_fields = [:integer_value, :string_value]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
