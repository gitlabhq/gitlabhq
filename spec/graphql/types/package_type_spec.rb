# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Package'] do
  it { expect(described_class.graphql_name).to eq('Package') }

  it 'includes all the package fields' do
    expected_fields = %w[
        id name version created_at updated_at package_type
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
