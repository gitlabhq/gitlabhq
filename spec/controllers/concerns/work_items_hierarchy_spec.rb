# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItemsHierarchy do
  controller(ApplicationController) do
    include WorkItemsHierarchy
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  render_views

  before do
    sign_in user
    routes.draw { get :planning_hierarchy, to: "anonymous#planning_hierarchy" }
    controller.instance_variable_set(:@project, project)
  end

  it 'renders hierarchy' do
    stub_feature_flags(work_items_hierarchy: true)

    get :planning_hierarchy

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.body).to match(/id="js-work-items-hierarchy"/)
  end

  it 'renders 404' do
    stub_feature_flags(work_items_hierarchy: false)

    get :planning_hierarchy

    expect(response).to have_gitlab_http_status(:not_found)
    expect(response.body).not_to match(/id="js-work-items-hierarchy"/)
  end
end
