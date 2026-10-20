# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CommitsController, feature_category: :source_code_management do
  context 'unauthenticated user' do
    let_it_be_with_reload(:project) { create(:project, :repository, :public) }

    context 'GET show' do
      context 'without path' do
        let(:id) { "master" }

        it 'is successful' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

          expect(assigns(:commits)).to be_present
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "with path provided" do
        let(:id) { "master/README.md" }

        it "requires authentication" do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

          expect(assigns(:commits)).to be_nil
          expect(response).to redirect_to(new_user_session_path)
        end

        context 'when "require_login_for_commit_tree" FF is disabled' do
          before do
            stub_feature_flags(require_login_for_commit_tree: false)
          end

          it 'is successful' do
            get :show, params: { namespace_id: project.namespace, project_id: project, id: id }

            expect(assigns(:commits)).to be_present
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'GET signatures' do
      context 'without path' do
        let(:id) { "master" }

        it 'is successful' do
          get :signatures, params: { namespace_id: project.namespace, project_id: project, id: id, format: :json }

          expect(assigns(:commits)).to be_present
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "with path provided" do
        let(:id) { "master/README.md" }

        it "requires authentication" do
          get :signatures, params: { namespace_id: project.namespace, project_id: project, id: id, format: :json }

          expect(assigns(:commits)).to be_nil
          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'when "require_login_for_commit_tree" FF is disabled' do
          before do
            stub_feature_flags(require_login_for_commit_tree: false)
          end

          it 'is successful' do
            get :signatures, params: { namespace_id: project.namespace, project_id: project, id: id, format: :json }

            expect(assigns(:commits)).to be_present
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end
end
