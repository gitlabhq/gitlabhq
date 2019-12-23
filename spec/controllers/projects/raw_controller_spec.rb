# frozen_string_literal: true

require 'spec_helper'

describe Projects::RawController do
  include RepoHelpers

  let(:project) { create(:project, :public, :repository) }

  describe 'GET #show' do
    subject do
      get(:show,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            id: filepath
          })
    end

    context 'regular filename' do
      let(:filepath) { 'master/README.md' }

      it 'delivers ASCII file' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
        expect(response.header['Content-Disposition']).to eq('inline')
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
      end
    end

    context 'image header' do
      let(:filepath) { 'master/files/images/6049019_460s.jpg' }

      it 'leaves image content disposition' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(response.header['Content-Disposition']).to eq('inline')
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
      end
    end

    it_behaves_like 'a controller that can serve LFS files' do
      let(:filename) { 'lfs_object.iso' }
      let(:filepath) { "be93687/files/lfs/#{filename}" }
    end

    context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_cache do
      let(:file_path) { 'master/README.md' }

      before do
        stub_application_setting(raw_blob_request_limit: 5)
      end

      it 'prevents from accessing the raw file', :request_store do
        execute_raw_requests(requests: 5, project: project, file_path: file_path)

        expect { execute_raw_requests(requests: 1, project: project, file_path: file_path) }
          .to change { Gitlab::GitalyClient.get_request_count }.by(0)

        expect(response.body).to eq(_('You cannot access the raw file. Please wait a minute.'))
        expect(response).to have_gitlab_http_status(429)
      end

      it 'logs the event on auth.log' do
        attributes = {
          message: 'Application_Rate_Limiter_Request',
          env: :raw_blob_request_limit,
          remote_ip: '0.0.0.0',
          request_method: 'GET',
          path: "/#{project.full_path}/raw/#{file_path}"
        }

        expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once

        execute_raw_requests(requests: 6, project: project, file_path: file_path)
      end

      context 'when receiving an external storage request' do
        let(:token) { 'letmein' }

        before do
          stub_application_setting(
            static_objects_external_storage_url: 'https://cdn.gitlab.com',
            static_objects_external_storage_auth_token: token
          )
        end

        it 'does not prevent from accessing the raw file' do
          request.headers['X-Gitlab-External-Storage-Token'] = token
          execute_raw_requests(requests: 6, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when the request uses a different version of a commit' do
        it 'prevents from accessing the raw file' do
          # 3 times with the normal sha
          commit_sha = project.repository.commit.sha
          file_path = "#{commit_sha}/README.md"

          execute_raw_requests(requests: 3, project: project, file_path: file_path)

          # 3 times with the modified version
          modified_sha = commit_sha.gsub(commit_sha[0..5], commit_sha[0..5].upcase)
          modified_path = "#{modified_sha}/README.md"

          execute_raw_requests(requests: 3, project: project, file_path: modified_path)

          expect(response.body).to eq(_('You cannot access the raw file. Please wait a minute.'))
          expect(response).to have_gitlab_http_status(429)
        end
      end

      context 'when the throttling has been disabled' do
        before do
          stub_application_setting(raw_blob_request_limit: 0)
        end

        it 'does not prevent from accessing the raw file' do
          execute_raw_requests(requests: 10, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'with case-sensitive files' do
        it 'prevents from accessing the specific file' do
          create_file_in_repo(project, 'master', 'master', 'readme.md', 'Add readme.md')
          create_file_in_repo(project, 'master', 'master', 'README.md', 'Add README.md')

          commit_sha = project.repository.commit.sha
          file_path = "#{commit_sha}/readme.md"

          # Accessing downcase version of readme
          execute_raw_requests(requests: 6, project: project, file_path: file_path)

          expect(response.body).to eq(_('You cannot access the raw file. Please wait a minute.'))
          expect(response).to have_gitlab_http_status(429)

          # Accessing upcase version of readme
          file_path = "#{commit_sha}/README.md"

          execute_raw_requests(requests: 1, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'as a sessionless user' do
      let_it_be(:project) { create(:project, :private, :repository) }
      let_it_be(:user) { create(:user, static_object_token: 'very-secure-token') }
      let_it_be(:file_path) { 'master/README.md' }

      before do
        project.add_developer(user)
      end

      context 'when no token is provided' do
        it 'redirects to sign in page' do
          execute_raw_requests(requests: 1, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(302)
          expect(response.location).to end_with('/users/sign_in')
        end
      end

      context 'when a token param is present' do
        context 'when token is correct' do
          it 'calls the action normally' do
            execute_raw_requests(requests: 1, project: project, file_path: file_path, token: user.static_object_token)

            expect(response).to have_gitlab_http_status(200)
          end
        end

        context 'when token is incorrect' do
          it 'redirects to sign in page' do
            execute_raw_requests(requests: 1, project: project, file_path: file_path, token: 'foobar')

            expect(response).to have_gitlab_http_status(302)
            expect(response.location).to end_with('/users/sign_in')
          end
        end
      end

      context 'when a token header is present' do
        context 'when token is correct' do
          it 'calls the action normally' do
            request.headers['X-Gitlab-Static-Object-Token'] = user.static_object_token
            execute_raw_requests(requests: 1, project: project, file_path: file_path)

            expect(response).to have_gitlab_http_status(200)
          end
        end

        context 'when token is incorrect' do
          it 'redirects to sign in page' do
            request.headers['X-Gitlab-Static-Object-Token'] = 'foobar'
            execute_raw_requests(requests: 1, project: project, file_path: file_path)

            expect(response).to have_gitlab_http_status(302)
            expect(response.location).to end_with('/users/sign_in')
          end
        end
      end
    end
  end

  def execute_raw_requests(requests:, project:, file_path:, **params)
    requests.times do
      get :show, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: file_path
      }.merge(params)
    end
  end
end
