require 'spec_helper'

describe API::V3::Builds do
  set(:user) { create(:user) }
  let(:api_user) { user }
  set(:project) { create(:project, :repository, creator: user, public_builds: false) }
  let!(:developer) { create(:project_member, :developer, user: user, project: project) }
  let(:reporter) { create(:project_member, :reporter, project: project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  before do
    stub_artifacts_object_storage
  end

  describe 'GET /projects/:id/builds/:build_id/artifacts' do
    before do
      get v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user)
    end

    context 'when job with artifacts are stored remotely' do
      let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: build) }

      it 'returns location redirect' do
        get v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user)

        expect(response).to have_gitlab_http_status(302)
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter.user }

    before do
      build.success
    end

    def path_for_ref(ref = pipeline.ref, job = build.name)
      v3_api("/projects/#{project.id}/builds/artifacts/#{ref}/download?job=#{job}", api_user)
    end

    shared_examples 'a valid file' do
      context 'when artifacts are stored remotely' do
        let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: build) }

        before do
          build.reload

          get v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user)
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

        get path_for_ref('master')
      end

      it_behaves_like 'a valid file'
    end

    context 'with branch name containing slash' do
      before do
        pipeline.reload
        pipeline.update(ref: 'improve/awesome',
                        sha: project.commit('improve/awesome').sha)

        get path_for_ref('improve/awesome')
      end

      it_behaves_like 'a valid file'
    end
  end
end
