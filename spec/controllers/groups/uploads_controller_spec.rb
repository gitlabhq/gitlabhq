# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UploadsController, feature_category: :portfolio_management do
  include WorkhorseHelpers

  let(:model) { create(:group, :public) }
  let(:params) do
    { group_id: model }
  end

  let(:other_model) { create(:group, :public) }
  let(:other_params) do
    { group_id: other_model }
  end

  it_behaves_like 'handle uploads' do
    let(:uploader_class) { NamespaceFileUploader }
  end

  context 'with a moved group' do
    let!(:upload) { create(:upload, :issuable_upload, :with_file, model: model) }
    let(:group) { model }
    let(:old_path) { group.to_param + 'old' }
    let!(:redirect_route) { model.redirect_routes.create!(path: old_path) }
    let(:upload_path) { File.basename(upload.path) }

    it 'redirects to a file with the proper extension' do
      get :show, params: { group_id: old_path, filename: upload_path, secret: upload.secret }

      expect(response.location).to eq(show_group_uploads_url(group, upload.secret, upload_path))
      expect(response.location).to end_with(upload.path)
      expect(response).to have_gitlab_http_status(:redirect)
    end
  end

  describe "GET #show" do
    let(:filename) { "rails_sample.jpg" }
    let(:user)  { create(:user) }
    let(:jpg)   { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
    let(:txt)   { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
    let(:uploader_class) { NamespaceFileUploader }
    let(:secret) { uploader_class.generate_secret }

    let(:upload_service) do
      UploadService.new(model, jpg, uploader_class).execute
    end

    let(:show_upload) do
      get :show, params: params.merge(secret: secret, filename: filename)
    end

    before do
      allow(uploader_class).to receive(:generate_secret).and_return(secret)

      allow_next_instance_of(uploader_class) do |instance|
        allow(instance).to receive(:image?).and_return(true)
      end

      upload_service
    end

    context 'when the group is public' do
      before do
        model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      context "when not signed in" do
        it "responds with appropriate status" do
          show_upload

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'when uploader class does not match the upload' do
          let(:uploader_class) { FileUploader }

          it 'responds with status 404' do
            show_upload

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when filename does not match' do
          let(:invalid_filename) { 'invalid_filename.jpg' }

          it 'responds with status 404' do
            get :show, params: params.merge(secret: secret, filename: invalid_filename)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user doesn't have access to the model" do
          it "responds with status 200" do
            show_upload

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'when the group is private' do
      before do
        model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      context "when not signed in" do
        it "responds with appropriate status" do
          show_upload

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user doesn't have access to the model" do
          it "responds with status 200" do
            show_upload

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: { group_id: model.full_path }, format: :json
  end
end
