# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HooksController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe '#index' do
    it 'renders index with 200 status code' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  describe '#create' do
    it 'sets all parameters' do
      hook_params = {
        enable_ssl_verification: true,
        token: "TEST TOKEN",
        url: "http://example.com",

        push_events: true,
        tag_push_events: true,
        merge_requests_events: true,
        issues_events: true,
        confidential_note_events: true,
        confidential_issues_events: true,
        note_events: true,
        job_events: true,
        pipeline_events: true,
        wiki_page_events: true
      }

      post :create, params: { namespace_id: project.namespace, project_id: project, hook: hook_params }

      expect(response).to have_gitlab_http_status(:found)
      expect(ProjectHook.all.size).to eq(1)
      expect(ProjectHook.first).to have_attributes(hook_params)
    end
  end
end
