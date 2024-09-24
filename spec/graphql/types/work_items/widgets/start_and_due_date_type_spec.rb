# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::StartAndDueDateType, feature_category: :team_planning do
  context 'when on FOSS', unless: Gitlab.ee? do
    it 'exposes the expected fields' do
      expect(described_class).to have_graphql_fields(
        :type,
        :due_date,
        :start_date,
        :roll_up
      )
    end
  end
end
