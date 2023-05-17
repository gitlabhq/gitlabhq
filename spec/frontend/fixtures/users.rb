# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users (GraphQL fixtures)', feature_category: :user_profile do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:user) { create(:user) }

    context 'for user achievements' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:achievement1) { create(:achievement, namespace: group) }
      let_it_be(:achievement2) { create(:achievement, namespace: group) }
      let_it_be(:achievement3) { create(:achievement, namespace: group) }
      let_it_be(:achievement_from_private_group) { create(:achievement, namespace: private_group) }
      let_it_be(:achievement_with_avatar_and_description) do
        create(:achievement,
          namespace: group,
          description: 'Description',
          avatar: File.new(Rails.root.join('db/fixtures/development/rocket.jpg'), 'r'))
      end

      let(:user_achievements_query_path) { 'profile/components/graphql/get_user_achievements.query.graphql' }
      let(:query) { get_graphql_query_as_string(user_achievements_query_path) }

      before_all do
        group.add_guest(user)
      end

      it "graphql/get_user_achievements_empty_response.json" do
        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end

      it "graphql/get_user_achievements_with_avatar_and_description_response.json" do
        create(:user_achievement, user: user, achievement: achievement_with_avatar_and_description)

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end

      it "graphql/get_user_achievements_without_avatar_or_description_response.json" do
        create(:user_achievement, user: user, achievement: achievement1)

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end

      it 'graphql/get_user_achievements_from_private_group.json' do
        create(:user_achievement, user: user, achievement: achievement_from_private_group)

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end

      it "graphql/get_user_achievements_long_response.json" do
        [achievement1, achievement2, achievement3, achievement_with_avatar_and_description].each do |achievement|
          create(:user_achievement, user: user, achievement: achievement)
        end

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
