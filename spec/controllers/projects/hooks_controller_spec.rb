# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HooksController, feature_category: :webhooks do
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

    context 'with an existing token' do
      hook_params = {
        token: WebHook::SECRET_MASK,
        url: "http://example.com"
      }

      it 'does not change a token' do
        expect do
          post :update, params: params.merge({ hook: hook_params })
        end.not_to change { hook.reload.token }

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:alert]).to be_blank
      end
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
      expect(flash[:notice]).to include('was updated')

      expect(hook.reload.url_variables).to eq(
        'a' => 'updated',
        'c' => 'new'
      )
    end

    it 'adds, updates and deletes custom headers' do
      hook.update!(custom_headers: { 'a' => 'bar', 'b' => 'woo' })

      params[:hook] = {
        custom_headers: [
          { key: 'a', value: 'updated' },
          { key: 'c', value: 'new' }
        ]
      }

      put :update, params: params

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include('was updated')

      expect(hook.reload.custom_headers).to eq(
        'a' => 'updated',
        'c' => 'new'
      )
    end

    it 'does not update custom headers with the secret mask' do
      hook.update!(custom_headers: { 'a' => 'bar' })

      params[:hook] = {
        custom_headers: [
          { key: 'a', value: WebHook::SECRET_MASK },
          { key: 'c', value: 'new' }
        ]
      }

      put :update, params: params

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include('was updated')

      expect(hook.reload.custom_headers).to eq(
        'a' => 'bar',
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
        token: 'TEST TOKEN',
        url: 'http://example.com',
        branch_filter_strategy: 'regex',

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

        custom_webhook_template: '{"test":"test"}',

        url_variables: [{ key: 'token', value: 'some secret value' }]
      }

      params = { namespace_id: project.namespace, project_id: project, hook: hook_params }

      expect { post :create, params: params }.to change(ProjectHook, :count).by(1)

      project_hook = ProjectHook.order_id_desc.take

      expect(project_hook).to have_attributes(
        **hook_params.merge(url_variables: { 'token' => 'some secret value' })
      )
      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:alert]).to be_blank
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

    context 'when user does not have permission' do
      let(:user) { create(:user, developer_of: project) }

      it 'renders a 404' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
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
          .to receive(:execute).and_return(ServiceResponse.error(message: 'All is woe'))
      end

      it 'informs the user' do
        post :test, params: { namespace_id: project.namespace, project_id: project, id: hook }

        expect(flash[:alert]).to include('failed: All is woe')
      end
    end

    context 'when the endpoint receives requests above the limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
          .and_return(web_hook_test: { threshold: 1, interval: 1.minute })
      end

      it 'prevents making test requests' do
        expect_next_instance_of(TestHooks::ProjectService) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success(payload: { http_status: 200 }))
        end

        2.times { post :test, params: { namespace_id: project.namespace, project_id: project, id: hook } }

        expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
