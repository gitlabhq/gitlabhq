# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::LfsStorageController, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax
  include GitHttpHelpers
  include ProjectForksHelper

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

  shared_examples 'an error response' do |http_status, error_message, http_method, action|
    it "returns #{http_status} and includes '#{error_message}'" do
      send(http_method, action, params: params)

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

          it_behaves_like "an error response", :forbidden, 'Check your access level', :put, :upload_finalize
        end
      end
    end

    context 'when bad_request' do
      let(:service_response) { ServiceResponse.error(reason: :invalid_uploaded_file, message: 'SHA256 or size mismatch') }

      it_behaves_like "an error response", :bad_request, 'SHA256 or size mismatch', :put, :upload_finalize
    end

    context 'when unprocessable_entity' do
      let(:service_response) { ServiceResponse.error(reason: :unprocessable_entity, message: 'Unprocessable entity') }

      it_behaves_like "an error response", :unprocessable_entity, 'Unprocessable entity', :put, :upload_finalize
    end
  end

  describe 'GET #download' do
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:repository_path) { "#{private_project.full_path}.git" }
    let_it_be(:lfs_object) { create(:lfs_object, :with_file) }
    let_it_be(:token) { create(:personal_access_token, user: user, scopes: ['read_repository']) }
    let_it_be(:extra_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, token.token) } }

    before do
      create(:lfs_objects_project, project: private_project, lfs_object: lfs_object)
      request.headers.merge!(extra_headers)
    end

    context 'with permission to download the file' do
      before do
        private_project.add_developer(user)
      end

      context 'when the LFS object exists in the project' do
        it 'returns the file' do
          get :download, params: { repository_path: repository_path, oid: lfs_object.oid }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq lfs_object.file.read
        end

        context 'when the LFS object metadata exists but file is missing' do
          let_it_be(:broken_lfs_object) { create(:lfs_object) }
          let(:params) { { repository_path: repository_path, oid: broken_lfs_object.oid } }

          before do
            create(:lfs_objects_project, project: private_project, lfs_object: broken_lfs_object)
            broken_lfs_object.update_column(:file, nil)
          end

          it_behaves_like "an error response", :not_found, 'Not found', :get, :download
        end
      end

      context 'when the LFS doesn not exist in the project' do
        let_it_be(:other_lfs_object) { create(:lfs_object, :with_file) }
        let(:params) { { repository_path: repository_path, oid: other_lfs_object.oid } }

        it_behaves_like "an error response", :not_found, 'Not found', :get, :download
      end
    end

    # When an user doesn't have download access permission,
    # it returns a 404 to avoid exposing the existence of the container.
    # Refer to LfsRequet#lfs_check_access!
    context 'without permission' do
      let(:params) { { repository_path: repository_path, oid: lfs_object.oid } }

      before do
        private_project.add_guest(user)
      end

      it_behaves_like "an error response", :not_found, 'Not found', :get, :download
    end

    context 'with fork network access' do
      let_it_be(:original_project) { create(:project, :public) }
      let_it_be(:forked_project) { fork_project(original_project, user, repository: true) }
      let_it_be(:fork_repository_path) { "#{forked_project.full_path}.git" }
      let_it_be(:original_lfs_object) { create(:lfs_object, :with_file) }

      before do
        forked_project.add_developer(user)
        request.headers.merge!(extra_headers)
      end

      context 'when the LFS object is linked to the original project' do
        before do
          create(:lfs_objects_project, project: original_project, lfs_object: original_lfs_object)
        end

        it 'allows access to LFS object from original project through fork' do
          get :download, params: { repository_path: fork_repository_path, oid: original_lfs_object.oid }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq original_lfs_object.file.read
        end
      end

      context 'when the LFS object is not linked to the original project' do
        let(:params) { { repository_path: fork_repository_path, oid: original_lfs_object.oid } }

        it_behaves_like "an error response", :not_found, 'Not found', :get, :download
      end
    end
  end
end
