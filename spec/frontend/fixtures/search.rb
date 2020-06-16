# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  render_views

  before(:all) do
    clean_frontend_fixtures('search/')
  end

  it 'search/show.html' do
    get :show

    expect(response).to be_successful
  end

  context 'search within a project' do
    let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
    let(:project) { create(:project, :public, :repository, namespace: namespace, path: 'search-project') }

    it 'search/blob_search_result.html' do
      get :show, params: {
        search: 'Send',
        project_id: project.id,
        scope: :blobs
      }

      expect(response).to be_successful
    end
  end
end
