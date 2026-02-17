# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomAttribute'], feature_category: :groups_and_projects do
  it 'has the expected fields' do
    expected_fields = %w[key value]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
