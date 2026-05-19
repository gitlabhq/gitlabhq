# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Organizations::OrganizationStateEnum, feature_category: :organization do
  specify { expect(described_class.graphql_name).to eq('OrganizationState') }

  it 'exposes all organization states' do
    expect(described_class.values.keys).to match_array(
      ::Organizations::Organization.states.keys.map(&:upcase)
    )
  end
end
