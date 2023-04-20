# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::AchievementsFinder, feature_category: :user_profile do
  let_it_be(:group) { create(:group) }
  let_it_be(:achievements) { create_list(:achievement, 3, namespace: group) }

  let(:params) { {} }

  describe '#execute' do
    subject { described_class.new(group, params).execute }

    it 'returns all achievements' do
      expect(subject).to match_array(achievements)
    end

    context 'when ids param provided' do
      let(:params) { { ids: [achievements[0].id, achievements[1].id] } }

      it 'returns specified achievements' do
        expect(subject).to contain_exactly(achievements[0], achievements[1])
      end
    end
  end
end
