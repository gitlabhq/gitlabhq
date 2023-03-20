# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Achievements::AchievementsResolver, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:achievement) { create(:achievement, namespace: group) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Achievements::AchievementType.connection_type)
  end

  describe '#resolve' do
    it 'is not empty' do
      expect(resolve_achievements).not_to be_empty
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
    resolve(described_class, obj: group)
  end
end
