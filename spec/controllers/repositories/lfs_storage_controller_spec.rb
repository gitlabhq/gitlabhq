# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::LfsStorageController, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax
  include GitHttpHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pat) { create(:personal_access_token, user: user, scopes: ['write_repository']) }

  let(:lfs_enabled) { true }
  let(:params) do
    {
      repository_path: "#{project.full_path}.git",
      oid: '6b9765d3888aaec789e8c309eb05b05c3a87895d6ad70d2264bd7270fff665ac',
      size: '6725030'
    }
  end

  before do
    stub_config(lfs: { enabled: lfs_enabled })
  end

  describe 'PUT #upload_authorize' do
    let(:headers) { workhorse_internal_api_request_header }
    let(:extra_headers) { {} }

    before do
      request.headers.merge!(extra_headers)
      request.headers.merge!(headers)
    end

    subject do
      put :upload_authorize, params: params
    end

    context 'with unauthorized roles' do
      where(:user_role, :expected_status) do
        :guest     | :forbidden
        :anonymous | :unauthorized
      end

      with_them do
        let(:extra_headers) do
          if user_role == :anonymous
            {}
          else
            { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, pat.token) }
          end
        end

        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like 'returning response status', params[:expected_status]
      end
    end

    context 'with at least developer role' do
      let(:extra_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, pat.token) } }

      before do
        project.add_developer(user)
      end

      it 'sets Workhorse with a max limit' do
        expect(LfsObjectUploader).to receive(:workhorse_authorize).with(has_length: false, maximum_size: params[:size].to_i).and_call_original

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  shared_examples 'an error response' do |http_status, error_message|
    it "returns #{http_status} and includes '#{error_message}'" do
      put :upload_finalize, params: params

      expect(response).to have_gitlab_http_status(http_status)
      expect(response.body).to include(error_message)
    end
  end

  describe 'PUT #upload_finalize' do
    let(:service_instance) { instance_double(Lfs::FinalizeUploadService, execute: service_response) }

    let(:headers) { workhorse_internal_api_request_header }
    let(:extra_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, pat.token) } }

    before do
      request.headers.merge!(extra_headers)
      request.headers.merge!(headers)
      project.add_developer(user)
      allow(Lfs::FinalizeUploadService).to receive(:new).and_return(service_instance)
    end

    context 'when the FinalizeUploadService is successful' do
      let(:service_response) { ServiceResponse.success }

      it_behaves_like 'returning response status', :ok
    end

    context 'when lfs_forbidden' do
      [
        [:invalid_record, 'Invalid record'],
        [:invalid_path, 'Invalid path'],
        [:remote_store_error, 'Remote store error']
      ].each do |reason, message|
        context "when #{reason} raised" do
          let(:service_response) { ServiceResponse.error(reason: reason, message: message) }

          it_behaves_like "an error response", :forbidden, 'Check your access level'
        end
      end
    end

    context 'when bad_request' do
      let(:service_response) { ServiceResponse.error(reason: :invalid_uploaded_file, message: 'SHA256 or size mismatch') }

      it_behaves_like "an error response", :bad_request, 'SHA256 or size mismatch'
    end

    context 'when unprocessable_entity' do
      let(:service_response) { ServiceResponse.error(reason: :unprocessable_entity, message: 'Unprocessable entity') }

      it_behaves_like "an error response", :unprocessable_entity, 'Unprocessable entity'
    end
  end
end
