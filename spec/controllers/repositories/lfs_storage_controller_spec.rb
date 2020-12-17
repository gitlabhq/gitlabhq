# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::LfsStorageController do
  using RSpec::Parameterized::TableSyntax
  include GitHttpHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pat) { create(:personal_access_token, user: user, scopes: ['write_repository']) }

  let(:lfs_enabled) { true }

  before do
    stub_config(lfs: { enabled: lfs_enabled })
  end

  describe 'PUT #upload_finalize' do
    let(:headers) { workhorse_internal_api_request_header }
    let(:extra_headers) { {} }
    let(:uploaded_file) { temp_file }

    let(:params) do
      {
        repository_path: "#{project.full_path}.git",
        oid: '6b9765d3888aaec789e8c309eb05b05c3a87895d6ad70d2264bd7270fff665ac',
        size: '6725030'
      }
    end

    before do
      request.headers.merge!(extra_headers)
      request.headers.merge!(headers)

      if uploaded_file
        allow_next_instance_of(ActionController::Parameters) do |params|
          allow(params).to receive(:[]).and_call_original
          allow(params).to receive(:[]).with(:file).and_return(uploaded_file)
        end
      end
    end

    after do
      FileUtils.rm_r(temp_file) if temp_file
    end

    subject do
      put :upload_finalize, params: params
    end

    context 'with lfs enabled' do
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

        it 'creates the objects' do
          expect { subject }
            .to change { LfsObject.count }.by(1)
            .and change { LfsObjectsProject.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'without the workhorse header' do
          let(:headers) { {} }

          it { expect { subject }.to raise_error(JWT::DecodeError) }
        end

        context 'without file' do
          let(:uploaded_file) { nil }

          it_behaves_like 'returning response status', :unprocessable_entity
        end

        context 'with an invalid file' do
          let(:uploaded_file) { 'test' }

          it_behaves_like 'returning response status', :unprocessable_entity
        end

        context 'when an expected error' do
          [
            ActiveRecord::RecordInvalid,
            UploadedFile::InvalidPathError,
            ObjectStorage::RemoteStoreError
          ].each do |exception_class|
            context "#{exception_class} raised" do
              it 'renders lfs forbidden' do
                expect(LfsObjectsProject).to receive(:safe_find_or_create_by!).and_raise(exception_class)

                subject

                expect(response).to have_gitlab_http_status(:forbidden)
                expect(json_response['documentation_url']).to be_present
                expect(json_response['message']).to eq('Access forbidden. Check your access level.')
              end
            end
          end
        end

        context 'when existing file has been deleted' do
          let(:lfs_object) { create(:lfs_object, :with_file) }

          before do
            FileUtils.rm(lfs_object.file.path)
            params[:oid] = lfs_object.oid
            params[:size] = lfs_object.size
          end

          it 'replaces the file' do
            expect(Gitlab::AppJsonLogger).to receive(:info).with(message: "LFS file replaced because it did not exist", oid: lfs_object.oid, size: lfs_object.size)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(lfs_object.reload.file).to exist
          end

          context 'with invalid file' do
            before do
              allow_next_instance_of(ActionController::Parameters) do |params|
                allow(params).to receive(:[]).and_call_original
                allow(params).to receive(:[]).with(:file).and_return({})
              end
            end

            it 'renders LFS forbidden' do
              subject

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(lfs_object.reload.file).not_to exist
            end
          end
        end

        context 'when file is not stored' do
          it 'renders unprocessable entity' do
            expect(controller).to receive(:store_file!).and_return(nil)

            subject

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(response.body).to eq('Unprocessable entity')
          end
        end
      end
    end

    context 'with lfs disabled' do
      let(:lfs_enabled) { false }
      let(:extra_headers) { { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, pat.token) } }

      it_behaves_like 'returning response status', :not_implemented
    end

    def temp_file
      upload_path = LfsObjectUploader.workhorse_local_upload_path
      file_path = "#{upload_path}/lfs"

      FileUtils.mkdir_p(upload_path)
      File.write(file_path, 'test')

      UploadedFile.new(file_path, filename: File.basename(file_path))
    end
  end
end
