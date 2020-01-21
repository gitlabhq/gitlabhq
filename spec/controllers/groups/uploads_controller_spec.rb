# frozen_string_literal: true

require 'spec_helper'

describe Groups::UploadsController do
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
    let!(:redirect_route) { model.redirect_routes.create(path: old_path) }
    let(:upload_path) { File.basename(upload.path) }

    it 'redirects to a file with the proper extension' do
      get :show, params: { group_id: old_path, filename: upload_path, secret: upload.secret }

      expect(response.location).to eq(show_group_uploads_url(group, upload.secret, upload_path))
      expect(response.location).to end_with(upload.path)
      expect(response).to have_gitlab_http_status(:redirect)
    end
  end

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: { group_id: model.full_path }, format: :json
  end
end
