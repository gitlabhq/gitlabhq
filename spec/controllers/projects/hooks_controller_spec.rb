# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HooksController do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }

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

  describe '#update' do
    let_it_be(:hook) { create(:project_hook, project: project) }

    let(:params) do
      { namespace_id: project.namespace, project_id: project, id: hook.id }
    end

    it 'adds, updates and deletes URL variables' do
      hook.update!(url_variables: { 'a' => 'bar', 'b' => 'woo' })

      params[:hook] = {
        url_variables: [
          { key: 'a', value: 'updated' },
          { key: 'b', value: nil },
          { key: 'c', value: 'new' }
        ]
      }

      put :update, params: params

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include('successfully updated')

      expect(hook.reload.url_variables).to eq(
        'a' => 'updated',
        'c' => 'new'
      )
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
      expect(response).to render_template('shared/hook_logs/_index')
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
        deployment_events: true,

        url_variables: [{ key: 'token', value: 'some secret value' }]
      }

      post :create, params: { namespace_id: project.namespace, project_id: project, hook: hook_params }

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:alert]).to be_blank
      expect(ProjectHook.count).to eq(1)
      expect(ProjectHook.first).to have_attributes(hook_params.except(:url_variables))
      expect(ProjectHook.first).to have_attributes(url_variables: { 'token' => 'some secret value' })
    end

    it 'alerts the user if the new hook is invalid' do
      hook_params = {
        token: "TEST\nTOKEN",
        url: "http://example.com"
      }

      post :create, params: { namespace_id: project.namespace, project_id: project, hook: hook_params }

      expect(flash[:alert]).to be_present
      expect(ProjectHook.count).to eq(0)
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

    context 'when the hook executes successfully' do
      before do
        stub_request(:post, hook.url).to_return(status: 200)
      end

      it 'informs the user' do
        post :test, params: { namespace_id: project.namespace, project_id: project, id: hook }

        expect(flash[:notice]).to include('executed successfully')
        expect(flash[:notice]).to include('HTTP 200')
      end
    end

    context 'when the hook runs, but fails' do
      before do
        stub_request(:post, hook.url).to_return(status: 400)
      end

      it 'informs the user' do
        post :test, params: { namespace_id: project.namespace, project_id: project, id: hook }

        expect(flash[:alert]).to include('executed successfully but')
        expect(flash[:alert]).to include('HTTP 400')
      end
    end

    context 'when the hook fails completely' do
      before do
        allow_next(::TestHooks::ProjectService)
          .to receive(:execute).and_return({ message: 'All is woe' })
      end

      it 'informs the user' do
        post :test, params: { namespace_id: project.namespace, project_id: project, id: hook }

        expect(flash[:alert]).to include('failed: All is woe')
      end
    end

    context 'when the endpoint receives requests above the limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
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
