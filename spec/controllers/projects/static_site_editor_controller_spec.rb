# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::StaticSiteEditorController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }
  let(:data) { instance_double(Hash) }

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

      %w[developer maintainer].each do |role|
        context "as #{role}" do
          before_all do
            project.add_role(user, role)
          end

          before do
            sign_in(user)
            get :show, params: default_params
          end

          it 'renders the edit page' do
            expect(response).to render_template(:show)
          end

          it 'assigns a required variables' do
            expect(assigns(:data)).to eq(data)
            expect(assigns(:ref)).to eq('master')
            expect(assigns(:path)).to eq('README.md')
          end

          context 'when combination of ref and path is incorrect' do
            let(:default_params) { super().merge(id: 'unknown') }

            it 'responds with 404 page' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when invalid config file' do
            let(:service_response) { ServiceResponse.error(message: 'invalid') }

            it 'redirects to project page and flashes error message' do
              expect(response).to redirect_to(project_path(project))
              expect(response).to set_flash[:alert].to('invalid')
            end
          end
        end
      end
    end
  end
end
