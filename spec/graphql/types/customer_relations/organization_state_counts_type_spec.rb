# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationStateCounts'] do
  include GraphqlHelpers

  let(:fields) do
    %w[
      all
      active
      inactive
    ]
  end

  let(:object) do
    {
      'inactive' => 3,
      'active' => 4
    }
  end

  it { expect(described_class.graphql_name).to eq('OrganizationStateCounts') }
  it { expect(described_class).to have_graphql_fields(fields) }

  describe '#all' do
    it 'returns the sum of all counts' do
      expect(resolve_field(:all, object)).to eq(7)
    end
  end
end
