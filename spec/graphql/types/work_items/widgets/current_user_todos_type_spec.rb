# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::CurrentUserTodosType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[current_user_todos type]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
