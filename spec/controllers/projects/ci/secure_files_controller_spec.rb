# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ci::SecureFilesController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:show_request) { get :show, params: { namespace_id: project.namespace, project_id: project } }

  describe 'GET #show' do
    context 'when the :ci_secure_files feature flag is enabled' do
      context 'with enough privileges' do
        before do
          stub_feature_flags(ci_secure_files: true)
          sign_in(user)
          project.add_developer(user)
          show_request
        end

        it { expect(response).to have_gitlab_http_status(:ok) }

        it 'renders show page' do
          expect(response).to render_template :show
        end
      end
    end

    context 'when the :ci_secure_files feature flag is disabled' do
      context 'with enough privileges' do
        before do
          stub_feature_flags(ci_secure_files: false)
          sign_in(user)
          project.add_developer(user)
          show_request
        end

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'without enough privileges' do
      before do
        sign_in(user)
        project.add_reporter(user)
        show_request
      end

      it 'responds with 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'an unauthenticated user' do
      before do
        show_request
      end

      it 'redirects to sign in' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end
