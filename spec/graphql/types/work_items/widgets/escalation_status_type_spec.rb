# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::EscalationStatusType, feature_category: :incident_management do
  it 'exposes the expected fields' do
    expected_fields = %i[type escalation_status]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
