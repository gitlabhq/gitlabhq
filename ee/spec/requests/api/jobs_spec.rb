require 'spec_helper'

describe API::Jobs do
  set(:project) do
    create(:project, :repository, public_builds: false)
  end

  set(:pipeline) do
    create(:ci_empty_pipeline, project: project,
                               sha: project.commit.id,
                               ref: project.default_branch)
  end

  let!(:job) { create(:ci_build, :success, pipeline: pipeline) }

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:cross_project_pipeline_enabled) { true }
  let(:object_storage_enabled) { true }

  before do
    stub_licensed_features(cross_project_pipelines: cross_project_pipeline_enabled,
                           object_storage: object_storage_enabled)
    project.add_developer(user)
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    shared_examples 'downloads artifact' do
      let(:download_headers) do
        { 'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
      end

      it 'returns specific job artifacts' do
        expect(response).to have_gitlab_http_status(200)
        expect(response.headers).to include(download_headers)
        expect(response.body).to match_file(job.artifacts_file.file.file)
      end
    end

    context 'for normal authentication when job with artifacts are stored remotely' do
      before do
        stub_artifacts_object_storage(proxy_download: proxy_download)

        create(:ci_job_artifact, :archive, :remote_store, job: job)

        get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
      end

      context 'when proxy download is enabled' do
        let(:proxy_download) { true }

        it 'responds with the workhorse send-url' do
          expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("send-url:")
        end
      end

      context 'when proxy download is disabled' do
        let(:proxy_download) { false }

        it 'returns location redirect' do
          expect(response).to have_gitlab_http_status(302)
        end
      end
    end

    context 'authorized by job_token' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

      before do
        get api("/projects/#{project.id}/jobs/#{job.id}/artifacts"), job_token: job.token
      end

      context 'user is developer' do
        let(:api_user) { user }

        it_behaves_like 'downloads artifact'
      end

      context 'when anonymous user is accessing private artifacts' do
        let(:api_user) { nil }

        it 'hides artifacts and rejects request' do
          expect(project).to be_private
          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'feature is disabled for EES' do
        let(:api_user) { user }
        let(:cross_project_pipeline_enabled) { false }

        it 'disallows access to the artifacts' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter }
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    before do
      stub_artifacts_object_storage(licensed: :skip)
      job.success
    end

    def get_for_ref(ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/download", api_user), job: job_name
    end

    context 'find proper job' do
      shared_examples 'a valid file' do
        context 'when artifacts are stored remotely' do
          let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
            job.reload

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          it 'returns location redirect' do
            expect(response).to have_gitlab_http_status(302)
          end
        end
      end

      context 'with regular branch' do
        before do
          pipeline.reload
          pipeline.update(ref: 'master',
                          sha: project.commit('master').sha)

          get_for_ref('master')
        end

        it_behaves_like 'a valid file'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get_for_ref('improve/awesome')
        end

        it_behaves_like 'a valid file'
      end

      context 'when using job_token to authenticate' do
        before do
          pipeline.reload
          pipeline.update(ref: 'master',
                          sha: project.commit('master').sha)

          get api("/projects/#{project.id}/jobs/artifacts/master/download"), job: job.name, job_token: job.token
        end

        context 'when user is reporter' do
          it_behaves_like 'a valid file'
        end

        context 'when user is admin, but not member' do
          let(:api_user) { create(:admin) }
          let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

          it 'does not allow to see that artfiact is present' do
            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end
  end
end
