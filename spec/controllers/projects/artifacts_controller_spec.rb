# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ArtifactsController, feature_category: :job_artifacts do
  include RepoHelpers

  let(:user) { project.first_owner }
  let_it_be(:project) { create(:project, :repository, :public) }

  let_it_be(:pipeline, reload: true) do
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit.sha,
      ref: project.default_branch,
      status: 'success'
    )
  end

  let!(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    render_views

    it 'renders the page with data for the artifacts app' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('projects/artifacts/index')
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
      let(:filename) { job.job_artifacts_archive.filename }

      it 'sends the artifacts file' do
        expect(controller).to receive(:send_file)
                          .with(
                            job.artifacts_file.file.path,
                            hash_including(disposition: 'attachment', filename: filename)).and_call_original

        download_artifact

        expect(response.headers['Content-Disposition'])
          .to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
      end
    end

    context 'when artifact is set as private' do
      let(:filename) { job.artifacts_file.filename }

      before do
        job.job_artifacts.update_all(accessibility: 'private')
      end

      context 'and user is not authoirized' do
        let(:user) { create(:user) }

        it 'returns forbidden' do
          download_artifact(file_type: 'archive')

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'and user has access to project' do
        it 'downloads' do
          expect(controller).to receive(:send_file)
                          .with(
                            job.artifacts_file.file.path,
                            hash_including(disposition: 'attachment', filename: filename)).and_call_original

          download_artifact(file_type: 'archive')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Disposition'])
            .to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
        end
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
            expect(controller).to receive(:send_file).with(
              job.job_artifacts_codequality.file.path,
              hash_including(disposition: 'attachment', filename: filename)
            ).and_call_original

            download_artifact(file_type: file_type)

            expect(response.headers['Content-Disposition'])
              .to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
          end
        end

        context 'when file is stored remotely' do
          let(:cdn_config) {}

          before do
            stub_artifacts_object_storage(cdn: cdn_config)
            create(:ci_job_artifact, :remote_store, :codequality, job: job)
            allow(Gitlab::ApplicationContext).to receive(:push).and_call_original
          end

          it 'sends the codequality report' do
            expect(Gitlab::ApplicationContext)
              .to receive(:push).with(artifact: an_instance_of(Ci::JobArtifact)).and_call_original

            expect(controller).to receive(:redirect_to).and_call_original

            download_artifact(file_type: file_type)
          end

          context 'when proxied' do
            it 'sends the codequality report' do
              expect(Gitlab::Workhorse).to receive(:send_url).and_call_original

              download_artifact(file_type: file_type, proxy: true)
            end
          end

          context 'when Google CDN is configured' do
            let(:cdn_config) do
              {
                'provider' => 'Google',
                'url' => 'https://cdn.example.org',
                'key_name' => 'some-key',
                'key' => Base64.urlsafe_encode64(SecureRandom.hex)
              }
            end

            before do
              request.env['action_dispatch.remote_ip'] = '18.245.0.42'
            end

            it 'redirects to a Google CDN request' do
              expect(Gitlab::ApplicationContext)
                .to receive(:push).with(artifact: an_instance_of(Ci::JobArtifact)).and_call_original
              expect(Gitlab::ApplicationContext).to receive(:push).with(artifact_used_cdn: true).and_call_original

              download_artifact(file_type: file_type)

              expect(response.redirect_url).to start_with("https://cdn.example.org/")
            end
          end
        end
      end
    end

    context 'when downloading a debug trace' do
      let(:file_type) { 'trace' }
      let(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      before do
        allow_next_found_instance_of(Ci::Build) do |build|
          allow(build).to receive(:debug_mode?).and_return(true)
        end
      end

      context 'when the user does not have update_build permissions' do
        let(:user) { create(:user) }

        before do
          project.add_guest(user)
        end

        render_views

        it 'denies the user access' do
          download_artifact(file_type: file_type)

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.body).to include(
            'You must have developer or higher permissions in the associated project to view job logs when debug trace is enabled. ' \
            'To disable debug trace, set the &#39;CI_DEBUG_TRACE&#39; and &#39;CI_DEBUG_SERVICES&#39; variables to &#39;false&#39; ' \
            'in your pipeline configuration or CI/CD settings. If you must view this job log, a project maintainer or owner must ' \
            'add you to the project with developer permissions or higher.'
          )
        end
      end

      context 'when the user has update_build permissions' do
        let(:filename) { job.job_artifacts_trace.file.filename }

        it 'sends the trace' do
          download_artifact(file_type: file_type)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Disposition'])
            .to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
        end
      end
    end
  end

  describe 'GET browse' do
    context 'for public artifacts' do
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

    context 'for private artifacts' do
      before do
        job.job_artifacts.update_all(accessibility: 'private')
      end

      context 'when the directory exists' do
        let(:user) { create(:user) }

        it 'responds not found' do
          get :browse, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'other_artifacts_0.1.2' }

          expect(response).to be_not_found
        end
      end
    end
  end

  describe 'GET external_file' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
    end

    context 'when the file exists' do
      it 'renders the file view' do
        path = 'ci_artifacts.txt'

        get :external_file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: path }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the file does not exist' do
      it 'responds Not Found' do
        get :external_file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: 'unknown' }

        expect(response).to have_gitlab_http_status(:not_found)
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
        context 'when the external redirect page is enabled' do
          before do
            stub_application_setting(enable_artifact_external_redirect_warning_page: true)
          end

          it 'redirects to the user-generated content warning page' do
            path = 'ci_artifacts.txt'

            get :file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: path }

            expect(response).to redirect_to(external_file_project_job_artifacts_path(project, job, path: path))
          end
        end

        context 'when the external redirect page is disabled' do
          before do
            stub_application_setting(enable_artifact_external_redirect_warning_page: false)
          end

          it 'renders the file view' do
            path = 'ci_artifacts.txt'

            get :file, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: path }

            expect(response).to have_gitlab_http_status(:found)
          end
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
          expect(response.headers['Gitlab-Workhorse-Detect-Content-Type']).to eq('true')
          expect(send_data).to start_with('artifacts-entry:')

          expect(params.keys).to eq(%w[Archive Entry])
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
            base64_params = send_data.delete_prefix('artifacts-entry:')
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

      context 'when artifacts archive is missing' do
        let!(:job) { create(:ci_build, :success, pipeline: pipeline) }

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
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

      context 'fetching an private artifact' do
        let(:user) { create(:user) }

        before do
          job.job_artifacts.update_all(accessibility: 'private')
        end

        it 'responds with not found' do
          subject

          expect(response).to be_not_found
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
          pipeline.update!(ref: 'master', sha: project.commit('master').sha)

          get :latest_succeeded, params: params_from_ref('master')
        end

        it_behaves_like 'redirect to the job'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.update!(ref: 'improve/awesome', sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params: params_from_ref('improve/awesome')
        end

        it_behaves_like 'redirect to the job'
      end

      context 'with branch name and path containing slashes' do
        before do
          pipeline.update!(ref: 'improve/awesome', sha: project.commit('improve/awesome').sha)

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

          create(
            :ci_pipeline,
            project: project,
            sha: project.commit.sha,
            ref: project.default_branch,
            status: 'failed'
          )

          get :latest_succeeded, params: params_from_ref(project.default_branch)
        end

        it_behaves_like 'redirect to the job'
      end
    end
  end
end
