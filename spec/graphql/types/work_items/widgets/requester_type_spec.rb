# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::RequesterType, feature_category: :service_desk do
  it 'exposes the expected fields' do
    expected_fields = %i[type email]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
