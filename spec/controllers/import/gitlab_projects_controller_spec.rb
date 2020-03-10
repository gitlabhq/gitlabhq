# frozen_string_literal: true

require 'spec_helper'

describe Import::GitlabProjectsController do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { namespace.owner }
  let(:file) { fixture_file_upload('spec/fixtures/project_export.tar.gz', 'text/plain') }

  before do
    sign_in(user)
  end

  describe 'POST create' do
    context 'with an invalid path' do
      it 'redirects with an error' do
        post :create, params: { namespace_id: namespace.id, path: '/test', file: file }

        expect(flash[:alert]).to start_with('Project could not be imported')
        expect(response).to have_gitlab_http_status(:found)
      end

      it 'redirects with an error when a relative path is used' do
        post :create, params: { namespace_id: namespace.id, path: '../test', file: file }

        expect(flash[:alert]).to start_with('Project could not be imported')
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'with a valid path' do
      it 'redirects to the new project path' do
        post :create, params: { namespace_id: namespace.id, path: 'test', file: file }

        expect(flash[:notice]).to include('is being imported')
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    it_behaves_like 'project import rate limiter'
  end

  describe 'POST authorize' do
    let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }

    before do
      request.headers['GitLab-Workhorse'] = '1.0'
      request.headers[Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER] = workhorse_token
    end

    it 'authorizes importing project with workhorse header' do
      post :authorize, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    it 'rejects requests that bypassed gitlab-workhorse or have invalid header' do
      request.headers[Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER] = 'INVALID_HEADER'

      expect { post :authorize, format: :json }.to raise_error(JWT::DecodeError)
    end

    context 'when using remote storage' do
      context 'when direct upload is enabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: true)
        end

        it 'responds with status 200, location of file remote store and object details' do
          post :authorize, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response).not_to have_key('TempPath')
          expect(json_response['RemoteObject']).to have_key('ID')
          expect(json_response['RemoteObject']).to have_key('GetURL')
          expect(json_response['RemoteObject']).to have_key('StoreURL')
          expect(json_response['RemoteObject']).to have_key('DeleteURL')
          expect(json_response['RemoteObject']).to have_key('MultipartUpload')
        end
      end

      context 'when direct upload is disabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: false)
        end

        it 'handles as a local file' do
          post :authorize, format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
          expect(json_response['RemoteObject']).to be_nil
        end
      end
    end
  end
end
