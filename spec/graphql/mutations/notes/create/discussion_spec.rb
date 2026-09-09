# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Notes::Create::Discussion, feature_category: :team_planning do
  describe '.authorization_scopes' do
    it 'includes the ai_workflows scope' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end
end
