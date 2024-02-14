# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users (JavaScript fixtures)', feature_category: :user_profile do
  include JavaScriptFixturesHelpers
  include ApiHelpers
  include DesignManagementTestHelpers

  let_it_be(:followers) { create_list(:user, 5) }
  let_it_be(:followees) { create_list(:user, 5) }
  let_it_be(:user) { create(:user, followers: followers, followees: followees) }

  describe API::Users, '(JavaScript fixtures)', type: :request do
    it 'api/users/followers/get.json' do
      get api("/users/#{user.id}/followers", user)

      expect(response).to be_successful
    end

    it 'api/users/following/get.json' do
      get api("/users/#{user.id}/following", user)

      expect(response).to be_successful
    end
  end

  describe UsersController, '(JavaScript fixtures)', type: :controller do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project_empty_repo, group: group) }

    if Gitlab.ee?
      include_context '[EE] with user contribution events'
    else
      include_context 'with user contribution events'
    end

    before do
      enable_design_management
      stub_licensed_features(epics: true)
      group.add_owner(user)
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'controller/users/activity.json' do
      get :activity, params: { username: user.username, limit: 100 }, format: :json

      expect(response).to be_successful
    end
  end

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    context 'for user achievements' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:multiple_achievement) { create(:achievement, namespace: group, name: 'Multiple') }
      let_it_be(:achievements) { create_list(:achievement, 6, namespace: group) }
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
        create(:user_achievement, user: user, achievement: multiple_achievement)

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end

      it 'graphql/get_user_achievements_from_private_group.json' do
        create(:user_achievement, user: user, achievement: achievement_from_private_group)

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end

      it "graphql/get_user_achievements_long_response.json" do
        [
          multiple_achievement, multiple_achievement, achievement_with_avatar_and_description, *achievements
        ].each do |achievement|
          create(:user_achievement, user: user, achievement: achievement)
        end

        post_graphql(query, current_user: user, variables: { id: user.to_global_id })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
