# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::OperationsController do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET #show' do
    it 'renders show template' do
      get :show, params: project_params(project)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context 'with insufficient permissions' do
      before do
        project.add_reporter(user)
      end

      it 'renders 404' do
        get :show, params: project_params(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to signup page' do
        get :show, params: project_params(project)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with insufficient permissions' do
      before do
        project.add_reporter(user)
      end

      it 'renders 404' do
        patch :update, params: project_params(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to signup page' do
        patch :update, params: project_params(project)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  shared_context 'PATCH #update' do
    let(:operations_update_service) { instance_double(::Projects::Operations::UpdateService) }
    let(:operations_url) { project_settings_operations_url(project) }

    let(:permitted_params) do
      ActionController::Parameters.new(params).permit!
    end

    context 'format json' do
      context 'when update succeeds' do
        before do
          stub_operations_update_service_returning(status: :success)
        end

        it 'returns success status' do
          patch :update,
            params: project_params(project, params),
            format: :json

          expect(::Projects::Operations::UpdateService)
            .to have_received(:new).with(project, user, permitted_params)
          expect(operations_update_service).to have_received(:execute)
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('status' => 'success')
          expect(flash[:notice]).to eq('Your changes have been saved')
        end
      end

      context 'when update fails' do
        before do
          stub_operations_update_service_returning(
            status: :error,
            message: 'error message'
          )
        end

        it 'returns error' do
          patch :update,
            params: project_params(project, params),
            format: :json

          expect(::Projects::Operations::UpdateService)
            .to have_received(:new).with(project, user, permitted_params)
          expect(operations_update_service).to have_received(:execute)
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).not_to be_nil
        end
      end
    end
  end

  context 'error tracking' do
    describe 'GET #show' do
      context 'with existing setting' do
        let!(:error_tracking_setting) do
          create(:project_error_tracking_setting, project: project)
        end

        it 'loads existing setting' do
          get :show, params: project_params(project)

          expect(controller.helpers.error_tracking_setting)
            .to eq(error_tracking_setting)
        end
      end

      context 'without an existing setting' do
        it 'builds a new setting' do
          get :show, params: project_params(project)

          expect(controller.helpers.error_tracking_setting).to be_new_record
        end
      end
    end

    describe 'PATCH #update' do
      let(:params) do
        {
          error_tracking_setting_attributes: {
            enabled: '1',
            api_host: 'http://url',
            token: 'token',
            project: {
              slug: 'sentry-project',
              name: 'Sentry Project',
              organization_slug: 'sentry-org',
              organization_name: 'Sentry Org'
            }
          }
        }
      end

      it_behaves_like 'PATCH #update'
    end
  end

  private

  def project_params(project, params = {})
    {
      namespace_id: project.namespace,
      project_id: project,
      project: params
    }
  end

  def stub_operations_update_service_returning(return_value = {})
    allow(::Projects::Operations::UpdateService)
      .to receive(:new).with(project, user, permitted_params)
      .and_return(operations_update_service)
    allow(operations_update_service).to receive(:execute)
      .and_return(return_value)
  end
end
