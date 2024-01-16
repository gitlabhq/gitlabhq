# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::NotesType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[discussions type discussion_locked]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
