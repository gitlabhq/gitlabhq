# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::RepositoriesController do
  let(:project) { create(:project, :repository) }

  describe "GET archive" do
    before do
      allow(controller).to receive(:archive_rate_limit_reached?).and_return(false)
    end

    context 'as a guest' do
      it 'responds with redirect in correct format' do
        get :archive, params: { namespace_id: project.namespace, project_id: project, id: "master" }, format: "zip"

        expect(response.header["Content-Type"]).to start_with('text/html')
        expect(response).to be_redirect
      end
    end

    context 'as a user' do
      let(:user) { create(:user) }
      let(:archive_name) { "#{project.path}-master" }

      before do
        project.add_developer(user)
        sign_in(user)
      end

      it_behaves_like "hotlink interceptor" do
        let(:http_request) do
          get :archive, params: { namespace_id: project.namespace, project_id: project, id: "master" }, format: "zip"
        end
      end

      it "uses Gitlab::Workhorse" do
        get :archive, params: { namespace_id: project.namespace, project_id: project, id: "master" }, format: "zip"

        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      it 'responds with redirect to the short name archive if fully qualified' do
        get :archive, params: { namespace_id: project.namespace, project_id: project, id: "master/#{archive_name}" }, format: "zip"

        expect(assigns(:ref)).to eq("master")
        expect(assigns(:filename)).to eq(archive_name)
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      it 'responds with redirect for a path with multiple slashes' do
        get :archive, params: { namespace_id: project.namespace, project_id: project, id: "improve/awesome/#{archive_name}" }, format: "zip"

        expect(assigns(:ref)).to eq("improve/awesome")
        expect(assigns(:filename)).to eq(archive_name)
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      it 'prioritizes the id param over the ref param when both are specified' do
        get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'feature', ref: 'feature_conflict' }, format: 'zip'

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:ref)).to eq('feature')
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("git-archive:")
      end

      context "when the service raises an error" do
        before do
          allow(Gitlab::Workhorse).to receive(:send_git_archive).and_raise("Archive failed")
        end

        it "renders Not Found" do
          get :archive, params: { namespace_id: project.namespace, project_id: project, id: "master" }, format: "zip"

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when the request format is HTML" do
        it "renders 404" do
          get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master' }, format: "html"

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      describe 'rate limiting' do
        it 'rate limits user when thresholds hit' do
          expect(controller).to receive(:archive_rate_limit_reached?).and_return(true)

          get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master' }, format: "html"

          expect(response).to have_gitlab_http_status(:too_many_requests)
        end
      end

      describe 'caching' do
        it 'sets appropriate caching headers' do
          get_archive

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.header['ETag']).to be_present
          expect(response.cache_control[:public]).to eq(false)
          expect(response.cache_control[:max_age]).to eq(60)
          expect(response.cache_control[:no_store]).to be_nil
        end

        context 'when project is public' do
          let(:project) { create(:project, :repository, :public) }

          it 'sets appropriate caching headers' do
            get_archive

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.header['ETag']).to be_present
            expect(response.header['Cache-Control']).to include('max-age=60, public')
          end

          context 'and repo is private' do
            let(:project) { create(:project, :repository, :public, :repository_private) }

            it 'sets appropriate caching headers' do
              get_archive

              expect(response).to have_gitlab_http_status(:ok)
              expect(response.header['ETag']).to be_present
              expect(response.header['Cache-Control']).to include('max-age=60, private')
            end
          end
        end

        context 'when ref is a commit SHA' do
          it 'max-age is set to 3600 in Cache-Control header' do
            get_archive('ddd0f15ae83993f5cb66a927a28673882e99100b')

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.header['Cache-Control']).to include('max-age=3600')
          end
        end

        context 'when If-None-Modified header is set' do
          it 'returns a 304 status' do
            # Get the archive cached first
            get_archive

            request.headers['If-None-Match'] = response.headers['ETag']
            get_archive

            expect(response).to have_gitlab_http_status(:not_modified)
          end
        end

        def get_archive(id = 'feature')
          get :archive, params: { namespace_id: project.namespace, project_id: project, id: id }, format: 'zip'
        end
      end
    end

    context 'as a sessionless user' do
      let(:user) { create(:user) }

      before do
        project.add_developer(user)
      end

      context 'when no token is provided' do
        it 'redirects to sign in page' do
          get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master' }, format: 'zip'

          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when a token param is present' do
        context 'when token is correct' do
          it 'calls the action normally' do
            get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master', token: user.static_object_token }, format: 'zip'

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when token is incorrect' do
          it 'redirects to sign in page' do
            get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master', token: 'foobar' }, format: 'zip'

            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end

      context 'when a token header is present' do
        context 'when token is correct' do
          it 'calls the action normally' do
            request.headers['X-Gitlab-Static-Object-Token'] = user.static_object_token
            get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master' }, format: 'zip'

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when token is incorrect' do
          it 'redirects to sign in page' do
            request.headers['X-Gitlab-Static-Object-Token'] = 'foobar'
            get :archive, params: { namespace_id: project.namespace, project_id: project, id: 'master' }, format: 'zip'

            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end
    end
  end
end
