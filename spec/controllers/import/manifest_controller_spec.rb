# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ManifestController do
  include ImportSpecHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group)}

  before(:all) do
    group.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  def assign_session_group
    session[:manifest_import_repositories] = []
    session[:manifest_import_group_id] = group.id
  end

  describe 'GET status' do
    let(:repo1) { OpenStruct.new(id: 'test1', url: 'http://demo.host/test1') }
    let(:repo2) { OpenStruct.new(id: 'test2', url: 'http://demo.host/test2') }
    let(:repos) { [repo1, repo2] }

    before do
      assign_session_group

      session[:manifest_import_repositories] = repos
    end

    it "returns variables for json request" do
      project = create(:project, import_type: 'manifest', creator_id: user.id)

      get :status, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
      expect(json_response.dig("provider_repos", 0, "id")).to eq(repo1.id)
      expect(json_response.dig("provider_repos", 1, "id")).to eq(repo2.id)
      expect(json_response.dig("namespaces", 0, "id")).to eq(group.id)
    end

    it "does not show already added project" do
      project = create(:project, import_type: 'manifest', namespace: user.namespace, import_status: :finished, import_url: repo1.url)

      get :status, format: :json

      expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
      expect(json_response.dig("provider_repos").length).to eq(1)
      expect(json_response.dig("provider_repos", 0, "id")).not_to eq(repo1.id)
    end
  end
end
