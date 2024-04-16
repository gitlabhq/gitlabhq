# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Organizations::OrganizationUserAccessLevelEnum, feature_category: :cell do
  specify { expect(described_class.graphql_name).to eq('OrganizationUserAccessLevel') }

  it 'exposes all the existing access levels' do
    expect(described_class.values.keys).to include(*%w[DEFAULT OWNER])
  end
end
