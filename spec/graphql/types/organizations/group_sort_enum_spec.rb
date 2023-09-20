# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationGroupSort'], feature_category: :cell do
  let(:sort_values) do
    %w[
      ID_ASC
      ID_DESC
      NAME_ASC
      NAME_DESC
      PATH_ASC
      PATH_DESC
      UPDATED_AT_ASC
      UPDATED_AT_DESC
      CREATED_AT_ASC
      CREATED_AT_DESC
    ]
  end

  specify { expect(described_class.graphql_name).to eq('OrganizationGroupSort') }

  it 'exposes all the organization groups sort values' do
    expect(described_class.values.keys).to include(*sort_values)
  end
end
