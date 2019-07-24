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

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: { group_id: model.full_path }, format: :json
  end
end
