# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::CurrentUserTodosType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[current_user_todos type]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    it 'includes :ai_workflows scope for the currentUserTodos field' do
      expect(described_class.fields['currentUserTodos']).to include_graphql_scopes(:ai_workflows)
    end
  end
end
