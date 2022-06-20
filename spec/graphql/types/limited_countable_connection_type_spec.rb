# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::LimitedCountableConnectionType do
  it 'has the expected fields' do
    expected_fields = %i[count page_info]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
