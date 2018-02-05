require 'spec_helper'

describe Projects::HooksController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe '#index' do
    it 'redirects to settings/integrations page' do
      get(:index, namespace_id: project.namespace, project_id: project)

      expect(response).to redirect_to(
        project_settings_integrations_path(project)
      )
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
        confidential_issues_events: true,
        note_events: true,
        job_events: true,
        pipeline_events: true,
        wiki_page_events: true
      }

      post :create, namespace_id: project.namespace, project_id: project, hook: hook_params

      expect(response).to have_http_status(302)
      expect(ProjectHook.all.size).to eq(1)
      expect(ProjectHook.first).to have_attributes(hook_params)
    end
  end
end
