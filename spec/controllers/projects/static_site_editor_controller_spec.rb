# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::StaticSiteEditorController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  let(:data) { { key: 'value' } }

  describe 'GET index' do
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    it 'responds with 404 page' do
      get :index, params: default_params

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET show' do
    render_views

    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/README.md',
        return_url: 'http://example.com'
      }
    end

    let(:service_response) do
      ServiceResponse.success(payload: data)
    end

    before do
      allow_next_instance_of(::StaticSiteEditor::ConfigService) do |instance|
        allow(instance).to receive(:execute).and_return(service_response)
      end
    end

    context 'User roles' do
      context 'anonymous' do
        before do
          get :show, params: default_params
        end

        it 'redirects to sign in and returns' do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as guest' do
        before do
          project.add_guest(user)
          sign_in(user)
          get :show, params: default_params
        end

        it 'responds with 404 page' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "as developer" do
        before do
          allow(Gitlab::UsageDataCounters::StaticSiteEditorCounter).to receive(:increment_views_count)
          project.add_role(user, 'developer')
          sign_in(user)
          get :show, params: default_params
        end

        it 'redirects to the Web IDE' do
          get :show, params: default_params

          expected_path_regex = %r[-/ide/project/#{project.full_path}/edit/master/-/README.md]
          expect(response).to redirect_to(expected_path_regex)
        end

        it 'assigns ref and path variables' do
          expect(assigns(:ref)).to eq('master')
          expect(assigns(:path)).to eq('README.md')
        end

        context 'when combination of ref and path is incorrect' do
          let(:default_params) { super().merge(id: 'unknown') }

          it 'responds with 404 page' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
