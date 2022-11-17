# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ClustersController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project, :repository, namespace: namespace) }
  let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
  let(:user) { project.first_owner }

  render_views

  before do
    sign_in(user)
  end

  after do
    remove_repository(project)
  end

  it 'clusters/show_cluster.html' do
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: cluster
    }

    expect(response).to be_successful
  end
end
