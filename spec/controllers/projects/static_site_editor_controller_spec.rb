# frozen_string_literal: true

require 'spec_helper'

describe Projects::StaticSiteEditorController do
  let(:project) { create(:project, :public, :repository) }

  describe 'GET show' do
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/README.md',
        return_url: 'http://example.com'
      }
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
        let(:user) { create(:user) }

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
          let(:user) { create(:user) }

          before do
            project.add_role(user, role)
            sign_in(user)
            get :show, params: default_params
          end

          it 'renders the edit page' do
            expect(response).to render_template(:show)
          end

          it 'assigns a config variable' do
            expect(assigns(:config)).to be_a(Gitlab::StaticSiteEditor::Config)
          end

          it 'correctly assigns ref and path' do
            expect(assigns(:ref)).to eq('master')
            expect(assigns(:path)).to eq('README.md')
          end

          context 'when combination of ref and file path is incorrect' do
            let(:default_params) { super().merge(id: 'unknown') }

            it 'responds with 404 page' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end
    end
  end
end
