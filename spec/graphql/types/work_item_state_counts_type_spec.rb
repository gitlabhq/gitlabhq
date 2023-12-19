# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItemStateCountsType'], feature_category: :portfolio_management do
  specify { expect(described_class.graphql_name).to eq('WorkItemStateCountsType') }

  it 'exposes the expected fields' do
    expected_fields = %i[all opened closed]
    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
