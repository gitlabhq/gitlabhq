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

  before do
    stub_licensed_features(cross_project_pipelines: cross_project_pipeline_enabled)
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
end
