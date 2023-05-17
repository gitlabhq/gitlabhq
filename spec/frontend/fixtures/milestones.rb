# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MilestonesController, '(JavaScript fixtures)', :with_license, feature_category: :team_planning, type: :controller do
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user, feed_token: 'feedtoken:coldfeed') }
  let_it_be(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project_empty_repo, namespace: namespace, path: 'milestones-project') }

  render_views

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  after do
    remove_repository(project)
  end

  it 'milestones/new-milestone.html' do
    get :new, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }

    expect(response).to be_successful
  end

  private

  def render_milestone(milestone)
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: milestone.to_param
    }

    expect(response).to be_successful
  end
end
