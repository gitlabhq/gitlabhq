# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ArtifactsController do
  include RepoHelpers

  let(:user) { project.owner }
  let_it_be(:project) { create(:project, :repository, :public) }

  let_it_be(:pipeline, reload: true) do
    create(:ci_pipeline,
            project: project,
            sha: project.commit.sha,
            ref: project.default_branch,
            status: 'success')
  end

  let!(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    context 'when feature flag is on' do
      before do
        stub_feature_flags(artifacts_management_page: true)
      end

      it 'sets the artifacts variable' do
        subject

        expect(assigns(:artifacts)).to contain_exactly(*project.job_artifacts)
      end

      it 'sets the total size variable' do
        subject

        expect(assigns(:total_size)).to eq(project.job_artifacts.total_size)
      end

      describe 'pagination' do
        before do
          stub_const("#{described_class}::MAX_PER_PAGE", 1)
        end

        it 'paginates artifacts' do
          subject

          expect(assigns(:artifacts)).to contain_exactly(project.reload.job_artifacts.last)
        end
      end
    end

    context 'when feature flag is off' do
      before do
        stub_feature_flags(artifacts_management_page: false)
      end

      it 'renders no content' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'does not set the artifacts variable' do
        subject

        expect(assigns(:artifacts)).to eq(nil)
      end

      it 'does not set the total size variable' do
        subject

        expect(assigns(:total_size)).to eq(nil)
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:artifact) { job.job_artifacts.erasable.first }

    subject { delete :destroy, params: { namespace_id: project.namespace, project_id: project, id: artifact } }

    it 'deletes the artifact' do
      expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
      expect(artifact).not_to exist
    end

    it 'redirects to artifacts index page' do
      subject

      expect(response).to redirect_to(project_artifacts_path(project))
    end

    it 'sets the notice' do
      subject

      expect(flash[:notice]).to eq(_('Artifact was successfully deleted.'))
    end

    context 'when artifact deletion fails' do
      before do
        allow_any_instance_of(Ci::JobArtifact).to receive(:destroy).and_return(false)
      end

      it 'redirects to artifacts index page' do
        subject

        expect(response).to redirect_to(project_artifacts_path(project))
      end

      it 'sets the notice' do
        subject

        expect(flash[:notice]).to eq(_('Artifact could not be deleted.'))
      end
    end

    context 'when user is not authorized' do
      let(:user) { create(:user) }

      it 'does not delete the artifact' do
        expect { subject }.not_to change { Ci::JobArtifact.count }
      end
    end
  end

  describe 'GET download' do
    def download_artifact(extra_params = {})
      params = { namespace_id: project.namespace, project_id: project, job_id: job }.merge(extra_params)

      get :download, params: params
    end

    context 'when no file type is supplied' do
      let(:filename) { job.artifacts_file.filename }

      it 'sends the artifacts file' do
        expect(controller).to receive(:send_file)
                          .with(
                            job.artifacts_file.file.path,
                            hash_including(disposition: 'attachment', filename: filename)).and_call_original

        download_artifact

        expect(response.headers['Content-Disposition']).to eq(%Q(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
      end
    end

    context 'when a file type is supplied' do
      context 'when an invalid file type is supplied' do
        let(:file_type) { 'invalid' }

        it 'returns 404' do
          download_artifact(file_type: file_type)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when codequality file type is supplied' do
        let(:file_type) { 'codequality' }
        let(:filename) { job.job_artifacts_codequality.filename }

        context 'when file is stored locally' do
          before do
            create(:ci_job_artifact, :codequality, job: job)
          end

          it 'sends the codequality report' do
            expect(controller).to receive(:send_file)
                              .with(job.job_artifacts_codequality.file.path,
                                    hash_including(disposition: 'attachment', filename: filename)).and_call_original

            download_artifact(file_type: file_type)

            expect(response.headers['Content-Disposition']).to eq(%Q(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
          end
        end

        context 'when file is stored remotely' do
          before do
            stub_artifacts_object_storage
            create(:ci_job_artifact, :remote_store, :codequality, job: job)
          end

          it 'sends the codequality report' do
            expect(controller).to receive(:redirect_to).and_call_original

            download_artifact(file_type: file_type)
          end

          context 'when proxied' do
            it 'sends the codequality report' do
              expect(Gitlab::Workhorse).to receive(:send_url).and_call_original

              download_artifact(file_type: file_type, proxy: true)
            end
          end
        end
      end
    end
  end

  describe 'GET browse' do
    context 'when the directory exists' do
      it 'renders the browse view' do
        get :browse, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'other_artifacts_0.1.2' }

        expect(response).to render_template('projects/artifacts/browse')
      end
    end

    context 'when the directory does not exist' do
      it 'responds Not Found' do
        get :browse, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'unknown' }

        expect(response).to be_not_found
      end
    end
  end

  describe 'GET file' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    end

    context 'when the file is served by GitLab Pages' do
      before do
        allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
      end

      context 'when the file exists' do
        it 'renders the file view' do
          get :file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'ci_artifacts.txt' }

          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when the file does not exist' do
        it 'responds Not Found' do
          get :file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'unknown' }

          expect(response).to be_not_found
        end
      end
    end

    context 'when the file is served through Rails' do
      context 'when the file exists' do
        it 'renders the file view' do
          get :file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'ci_artifacts.txt' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('projects/artifacts/file')
        end
      end

      context 'when the file does not exist' do
        it 'responds Not Found' do
          get :file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'unknown' }

          expect(response).to be_not_found
        end
      end
    end

    context 'when the project is private' do
      let(:private_project) { create(:project, :repository, :private) }
      let(:pipeline) { create(:ci_pipeline, project: private_project) }
      let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

      before do
        private_project.add_developer(user)

        allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
      end

      it 'does not redirect the request' do
        get :file, params: { namespace_id: private_project.namespace, project_id: private_project, job_id: job, path: 'ci_artifacts.txt' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('projects/artifacts/file')
      end
    end

    context 'when the project is private and pages access control is enabled' do
      let(:private_project) { create(:project, :repository, :private) }
      let(:pipeline) { create(:ci_pipeline, project: private_project) }
      let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

      before do
        private_project.add_developer(user)

        allow(Gitlab.config.pages).to receive(:access_control).and_return(true)
        allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
      end

      it 'renders the file view' do
        get :file, params: { namespace_id: private_project.namespace, project_id: private_project, job_id: job, path: 'ci_artifacts.txt' }

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  describe 'GET raw' do
    let(:query_params) { { namespace_id: project.namespace, project_id: project, job_id: job, path: path } }

    subject { get(:raw, params: query_params) }

    context 'when the file exists' do
      let(:path) { 'ci_artifacts.txt' }
      let(:archive_matcher) { /build_artifacts.zip(\?[^?]+)?$/ }

      shared_examples 'a valid file' do
        it 'serves the file using workhorse' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(send_data).to start_with('artifacts-entry:')

          expect(params.keys).to eq(%w(Archive Entry))
          expect(params['Archive']).to start_with(archive_path)
          # On object storage, the URL can end with a query string
          expect(params['Archive']).to match(archive_matcher)
          expect(params['Entry']).to eq(Base64.encode64(path))
        end

        def send_data
          response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]
        end

        def params
          @params ||= begin
            base64_params = send_data.sub(/\Aartifacts\-entry:/, '')
            Gitlab::Json.parse(Base64.urlsafe_decode64(base64_params))
          end
        end
      end

      context 'when using local file storage' do
        it_behaves_like 'a valid file' do
          let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }
          let(:store) { ObjectStorage::Store::LOCAL }
          let(:archive_path) { JobArtifactUploader.root }
        end
      end

      context 'when using remote file storage' do
        before do
          stub_artifacts_object_storage
        end

        it_behaves_like 'a valid file' do
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }
          let!(:job) { create(:ci_build, :success, pipeline: pipeline) }
          let(:store) { ObjectStorage::Store::REMOTE }
          let(:archive_path) { 'https://' }
        end
      end

      context 'fetching an artifact of different type' do
        before do
          job.job_artifacts.each(&:destroy)
        end

        context 'when the artifact is zip' do
          let!(:artifact) { create(:ci_job_artifact, :lsif, job: job) }
          let(:path) { 'lsif/main.go.json' }
          let(:archive_matcher) { 'lsif.json.zip' }
          let(:query_params) { super().merge(file_type: :lsif, path: path) }

          it_behaves_like 'a valid file' do
            let(:store) { ObjectStorage::Store::LOCAL }
            let(:archive_path) { JobArtifactUploader.root }
          end
        end

        context 'when the artifact is not zip' do
          let(:query_params) { super().merge(file_type: :junit, path: '') }

          it 'responds with not found' do
            create(:ci_job_artifact, :junit, job: job)

            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'GET latest_succeeded' do
    def params_from_ref(ref = pipeline.ref, job_name = job.name, path = 'browse')
      {
        namespace_id: project.namespace,
        project_id: project,
        ref_name_and_path: File.join(ref, path),
        job: job_name
      }
    end

    context 'cannot find the job' do
      shared_examples 'not found' do
        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get :latest_succeeded, params: params_from_ref('TAIL', job.name)
        end

        it_behaves_like 'not found'
      end

      context 'has no such job' do
        before do
          get :latest_succeeded, params: params_from_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end

      context 'has no path' do
        before do
          get :latest_succeeded, params: params_from_ref(pipeline.sha, job.name, '')
        end

        it_behaves_like 'not found'
      end
    end

    context 'found the job and redirect' do
      shared_examples 'redirect to the job' do
        it 'redirects' do
          path = browse_project_job_artifacts_path(project, job)

          expect(response).to redirect_to(path)
        end
      end

      context 'with regular branch' do
        before do
          pipeline.update!(ref: 'master',
                          sha: project.commit('master').sha)

          get :latest_succeeded, params: params_from_ref('master')
        end

        it_behaves_like 'redirect to the job'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.update!(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params: params_from_ref('improve/awesome')
        end

        it_behaves_like 'redirect to the job'
      end

      context 'with branch name and path containing slashes' do
        before do
          pipeline.update!(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params: params_from_ref('improve/awesome', job.name, 'file/README.md')
        end

        it 'redirects' do
          path = file_project_job_artifacts_path(project, job, 'README.md')

          expect(response).to redirect_to(path)
        end
      end

      context 'with a failed pipeline on an updated master' do
        before do
          create_file_in_repo(project, 'master', 'master', 'test.txt', 'This is test')

          create(:ci_pipeline,
            project: project,
            sha: project.commit.sha,
            ref: project.default_branch,
            status: 'failed')

          get :latest_succeeded, params: params_from_ref(project.default_branch)
        end

        it_behaves_like 'redirect to the job'
      end
    end
  end
end
