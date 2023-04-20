# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Achievements::AchievementsResolver, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:achievements) { create_list(:achievement, 3, namespace: group) }

  let(:args) { {} }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Achievements::AchievementType.connection_type)
  end

  describe '#resolve' do
    it 'returns all achievements' do
      expect(resolve_achievements.items).to match_array(achievements)
    end

    context 'with ids argument' do
      let(:args) { { ids: [achievements[0].to_global_id, achievements[1].to_global_id] } }

      it 'returns the specified achievement' do
        expect(resolve_achievements.items).to contain_exactly(achievements[0], achievements[1])
      end
    end

    context 'when `achievements` feature flag is diabled' do
      before do
        stub_feature_flags(achievements: false)
      end

      it 'is empty' do
        expect(resolve_achievements).to be_empty
      end
    end
  end

  def resolve_achievements
    resolve(described_class, args: args, obj: group)
  end
end
