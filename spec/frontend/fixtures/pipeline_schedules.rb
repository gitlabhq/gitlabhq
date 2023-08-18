# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline schedules (JavaScript fixtures)' do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.first_owner }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }
  let!(:pipeline_schedule_inactive) { create(:ci_pipeline_schedule, :inactive, project: project, owner: user) }
  let!(:pipeline_schedule_populated) { create(:ci_pipeline_schedule, project: project, owner: user) }
  let!(:pipeline_schedule_variable1) { create(:ci_pipeline_schedule_variable, key: 'foo', value: 'foovalue', pipeline_schedule: pipeline_schedule_populated) }
  let!(:pipeline_schedule_variable2) { create(:ci_pipeline_schedule_variable, key: 'bar', value: 'barvalue', pipeline_schedule: pipeline_schedule_populated) }

  describe GraphQL::Query, type: :request do
    before do
      pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
    end

    fixtures_path = 'graphql/pipeline_schedules/'
    get_pipeline_schedules_query = 'get_pipeline_schedules.query.graphql'

    let_it_be(:query) do
      get_graphql_query_as_string("ci/pipeline_schedules/graphql/queries/#{get_pipeline_schedules_query}")
    end

    it "#{fixtures_path}#{get_pipeline_schedules_query}.json" do
      post_graphql(query, current_user: user, variables: { projectPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}#{get_pipeline_schedules_query}.single.json" do
      post_graphql(query, current_user: user, variables: { projectPath: project.full_path, ids: pipeline_schedule_populated.id })

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}#{get_pipeline_schedules_query}.as_guest.json" do
      guest = create(:user)
      project.add_guest(user)

      post_graphql(query, current_user: guest, variables: { projectPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end

    it "#{fixtures_path}#{get_pipeline_schedules_query}.take_ownership.json" do
      maintainer = create(:user)
      project.add_maintainer(maintainer)

      post_graphql(query, current_user: maintainer, variables: { projectPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end
end
