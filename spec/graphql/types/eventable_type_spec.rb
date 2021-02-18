# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::EventableType do
  it 'exposes events field' do
    expect(described_class).to have_graphql_fields(:events)
  end
end
