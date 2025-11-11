# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::StateEnum, feature_category: :permissions do
  specify { expect(described_class.graphql_name).to eq('AccessTokenState') }

  it 'exposes the expected state values' do
    expect(described_class.values).to match(
      'ACTIVE' => have_attributes(
        value: 'active'
      ),
      'INACTIVE' => have_attributes(
        value: 'inactive'
      )
    )
  end
end
