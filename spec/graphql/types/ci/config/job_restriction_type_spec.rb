# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Config::JobRestrictionType do
  specify { expect(described_class.graphql_name).to eq('CiConfigJobRestriction') }

  it 'exposes the expected fields' do
    expected_fields = %i[refs]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
