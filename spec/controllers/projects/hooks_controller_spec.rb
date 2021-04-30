# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HooksController do
  let_it_be(:project) { create(:project) }

  let(:user) { project.owner }

  before do
    sign_in(user)
  end

  describe '#index' do
    it 'renders index with 200 status code' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  describe '#edit' do
    let_it_be(:hook) { create(:project_hook, project: project) }

    let(:params) do
      { namespace_id: project.namespace, project_id: project, id: hook.id }
    end

    render_views

    it 'does not error if the hook cannot be found' do
      get :edit, params: params.merge(id: non_existing_record_id)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'assigns hook_logs' do
      get :edit, params: params

      expect(assigns[:hook]).to be_present
      expect(assigns[:hook_logs]).to be_empty
      it_renders_correctly
    end

    it 'handles when logs are present' do
      create_list(:web_hook_log, 3, web_hook: hook)

      get :edit, params: params

      expect(assigns[:hook]).to be_present
      expect(assigns[:hook_logs].count).to eq 3
      it_renders_correctly
    end

    it 'can paginate logs' do
      create_list(:web_hook_log, 21, web_hook: hook)

      get :edit, params: params.merge(page: 2)

      expect(assigns[:hook]).to be_present
      expect(assigns[:hook_logs].count).to eq 1
      it_renders_correctly
    end

    def it_renders_correctly
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:edit)
      expect(response).to render_template('projects/hook_logs/_index')
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
        wiki_page_events: true,
        deployment_events: true
      }

      post :create, params: { namespace_id: project.namespace, project_id: project, hook: hook_params }

      expect(response).to have_gitlab_http_status(:found)
      expect(ProjectHook.all.size).to eq(1)
      expect(ProjectHook.first).to have_attributes(hook_params)
    end
  end

  describe 'DELETE #destroy' do
    let!(:hook) { create(:project_hook, project: project) }
    let!(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { namespace_id: project.namespace, project_id: project, id: hook } }

    it_behaves_like 'Web hook destroyer'
  end

  describe '#test' do
    let(:hook) { create(:project_hook, project: project) }

    context 'when the endpoint receives requests above the limit' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
          .and_return(project_testing_hook: { threshold: 1, interval: 1.minute })
      end

      it 'prevents making test requests' do
        expect_next_instance_of(TestHooks::ProjectService) do |service|
          expect(service).to receive(:execute).and_return(http_status: 200)
        end

        2.times { post :test, params: { namespace_id: project.namespace, project_id: project, id: hook } }

        expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
