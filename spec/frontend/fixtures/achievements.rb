# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Achievements (JavaScript fixtures)', feature_category: :user_profile do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    let_it_be(:group) { create(:group, :public) }

    describe 'get_group_achievements.query.graphql' do
      let(:query_path) { 'achievements/components/graphql/get_group_achievements.query.graphql' }
      let(:query) { get_graphql_query_as_string(query_path) }

      it 'graphql/get_group_achievements_empty_response.json' do
        post_graphql(query, current_user: nil, variables: { group_full_path: group.full_path })

        expect_graphql_errors_to_be_empty
      end

      context 'with achievements' do
        before_all do
          create(:achievement, namespace: group, name: 'Hero')
          create(:achievement, namespace: group, name: 'Star')
          legend_avatar = fixture_file_upload('spec/fixtures/dk.png')
          legend = create(:achievement, namespace: group, name: 'Legend', avatar: legend_avatar)
          user_avatar = fixture_file_upload('spec/fixtures/rails_sample.png')
          recipient = create(:user, name: 'Git Lab', username: 'gitlab.user', avatar: user_avatar)
          create(:user_achievement, achievement: legend, user: recipient)
          create(:user_achievement, achievement: legend)
        end

        it 'graphql/get_group_achievements_response.json' do
          post_graphql(query, current_user: nil, variables: { group_full_path: group.full_path })

          expect_graphql_errors_to_be_empty
        end

        it 'graphql/get_group_achievements_paginated_response.json' do
          post_graphql(query, current_user: nil, variables: { group_full_path: group.full_path, first: 2 })

          expect_graphql_errors_to_be_empty
        end
      end
    end

    describe 'create_achievement.mutation.graphql' do
      let_it_be(:user) { create(:user) }
      let_it_be(:achievement) { create(:achievement, namespace: group, name: 'Hero') }

      let(:mutation_path) { 'achievements/components/graphql/create_achievement.mutation.graphql' }
      let(:mutation) { get_graphql_query_as_string(mutation_path) }
      let(:variables) { { input: { namespace_id: "gid://gitlab/Group/#{group.id}", name: achievement_name } } }

      before_all do
        group.add_maintainer(user)
      end

      before do
        post_graphql(mutation, current_user: user, variables: variables)
      end

      context 'with an available name' do
        let(:achievement_name) { 'New' }

        it 'graphql/create_achievement_response.json' do
          expect_graphql_errors_to_be_empty
        end
      end

      context 'with an existing name' do
        let(:achievement_name) { achievement.name }

        it 'graphql/create_achievement_error_response.json' do
          expect(graphql_data_at('achievements_create', 'errors')).to include('Name has already been taken')
        end
      end
    end
  end
end
