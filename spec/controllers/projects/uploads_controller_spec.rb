# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UploadsController, feature_category: :team_planning do
  include WorkhorseHelpers

  let(:model) { create(:project, :public) }
  let(:params) do
    { namespace_id: model.namespace.to_param, project_id: model }
  end

  let(:other_model) { create(:project, :public) }
  let(:other_params) do
    { namespace_id: other_model.namespace.to_param, project_id: other_model }
  end

  let(:legacy_version) { UploadsActions::ID_BASED_UPLOAD_PATH_VERSION - 1 }

  it_behaves_like 'handle uploads'

  context 'when the URL the old style, without /-/system' do
    it 'responds with a redirect to the login page' do
      get :show, params: { namespace_id: 'project', project_id: 'avatar', filename: 'foo.png', secret: 'bar' }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'with a moved project' do
    let!(:upload) { create(:upload, :issuable_upload, :with_file, model: model) }
    let(:project) { model }
    let(:upload_path) { File.basename(upload.path) }
    let!(:redirect_route) { project.redirect_routes.create!(path: project.full_path + 'old') }

    it 'redirects to a file with the proper extension' do
      get :show, params: { namespace_id: project.namespace, project_id: project.to_param + 'old', filename: File.basename(upload.path), secret: upload.secret }

      expect(response.location).to eq(show_project_uploads_url(project, upload.secret, upload_path))
      expect(response.location).to end_with(upload.path)
      expect(response).to have_gitlab_http_status(:redirect)
    end
  end

  context "when exception occurs" do
    before do
      allow(FileUploader).to receive(:workhorse_authorize).and_raise(SocketError.new)
      sign_in(create(:user))
    end

    it "responds with status internal_server_error" do
      post_authorize

      expect(response).to have_gitlab_http_status(:internal_server_error)
      expect(response.body).to eq(_('Error uploading file'))
    end
  end

  describe "GET #show" do
    let(:user)  { create(:user) }
    let(:filename) { "rails_sample.jpg" }
    let!(:upload) { create(:upload, :issuable_upload, :with_file, model: model, filename: filename) }

    let(:show_upload) do
      get :show, params: params.merge(secret: upload.secret, filename: filename)
    end

    it 'responds with status 404' do
      show_upload

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'with legacy upload' do
      let!(:upload) do
        create(:upload, :issuable_upload, :with_file, model: model, filename: filename, version: legacy_version)
      end

      context 'when project is private do' do
        before do
          model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        context "when not signed in" do
          context 'when the project has setting enforce_auth_checks_on_uploads true' do
            before do
              model.update!(enforce_auth_checks_on_uploads: true)
            end

            it "responds with status 302" do
              show_upload

              expect(response).to have_gitlab_http_status(:redirect)
            end
          end

          context 'when the project has setting enforce_auth_checks_on_uploads false' do
            before do
              model.update!(enforce_auth_checks_on_uploads: false)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user doesn't have access to the model" do
            context 'when the project has setting enforce_auth_checks_on_uploads true' do
              before do
                model.update!(enforce_auth_checks_on_uploads: true)
              end

              it "responds with status 404" do
                show_upload

                expect(response).to have_gitlab_http_status(:not_found)
              end
            end

            context 'when the project has setting enforce_auth_checks_on_uploads false' do
              before do
                model.update!(enforce_auth_checks_on_uploads: false)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end
      end

      context 'when project is public' do
        before do
          model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        end

        context "when not signed in" do
          context 'when the project has setting enforce_auth_checks_on_uploads true' do
            before do
              model.update!(enforce_auth_checks_on_uploads: true)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'when the project has setting enforce_auth_checks_on_uploads false' do
            before do
              model.update!(enforce_auth_checks_on_uploads: false)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user doesn't have access to the model" do
            context 'when the project has setting enforce_auth_checks_on_uploads true' do
              before do
                model.update!(enforce_auth_checks_on_uploads: true)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(:ok)
              end
            end

            context 'when the project has setting enforce_auth_checks_on_uploads false' do
              before do
                model.update!(enforce_auth_checks_on_uploads: false)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end
      end
    end
  end

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: { namespace_id: model.namespace, project_id: model.path }, format: :json
  end
end
