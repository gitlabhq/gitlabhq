# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetDefinitions::AssigneesType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[type can_invite_members]

    expected_fields.each do |field|
      expect(described_class).to have_graphql_field(field)
    end
  end
end
