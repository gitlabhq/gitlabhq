# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project (GraphQL fixtures)', feature_category: :groups_and_projects do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers
    include ProjectForksHelper

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:current_user) { create(:user) }

    describe 'writable forks' do
      writeable_forks_query_path = 'vue_shared/components/web_ide/get_writable_forks.query.graphql'

      let(:query) { get_graphql_query_as_string(writeable_forks_query_path) }

      subject { post_graphql(query, current_user: current_user, variables: { projectPath: project.full_path }) }

      before do
        project.add_developer(current_user)
      end

      context 'with none' do
        it "graphql/#{writeable_forks_query_path}_none.json" do
          subject

          expect_graphql_errors_to_be_empty
        end
      end

      context 'with some' do
        let_it_be(:fork1) { fork_project(project, nil, repository: true) }
        let_it_be(:fork2) { fork_project(project, nil, repository: true) }

        before_all do
          fork1.add_developer(current_user)
          fork2.add_developer(current_user)
        end

        it "graphql/#{writeable_forks_query_path}_some.json" do
          subject

          expect_graphql_errors_to_be_empty
        end
      end
    end
  end
end
