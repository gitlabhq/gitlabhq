# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::NotesType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[discussions notes type discussion_locked]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'field with :ai_workflows scope' do
    it 'includes :ai_workflows at the field level' do
      expect(described_class.fields['notes'].instance_variable_get(:@scopes)).to include(:ai_workflows)
    end
  end
end
