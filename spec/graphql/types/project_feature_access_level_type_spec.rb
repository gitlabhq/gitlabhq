# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectFeatureAccess'], feature_category: :groups_and_projects do
  specify { expect(described_class.graphql_name).to eq('ProjectFeatureAccess') }
  specify { expect(described_class).to require_graphql_authorizations(nil) }

  it 'has expected fields' do
    expected_fields = [:integer_value, :string_value]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
