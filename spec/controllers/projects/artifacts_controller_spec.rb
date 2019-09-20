# frozen_string_literal: true

require 'spec_helper'

describe Projects::ArtifactsController do
  let(:user) { project.owner }
  set(:project) { create(:project, :repository, :public) }

  let(:pipeline) do
    create(:ci_pipeline,
            project: project,
            sha: project.commit.sha,
            ref: project.default_branch,
            status: 'success')
  end

  let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    sign_in(user)
  end

  describe 'GET download' do
    def download_artifact(extra_params = {})
      params = { namespace_id: project.namespace, project_id: project, job_id: job }.merge(extra_params)

      get :download, params: params
    end

    context 'when no file type is supplied' do
      let(:filename) { job.artifacts_file.filename }

      it 'sends the artifacts file' do
        # Notice the filename= is omitted from the disposition; this is because
        # Rails 5 will append this header in send_file
        expect(controller).to receive(:send_file)
                          .with(
                            job.artifacts_file.file.path,
                            hash_including(disposition: %Q(attachment; filename*=UTF-8''#{filename}))).and_call_original

        download_artifact
      end
    end

    context 'when a file type is supplied' do
      context 'when an invalid file type is supplied' do
        let(:file_type) { 'invalid' }

        it 'returns 404' do
          download_artifact(file_type: file_type)

          expect(response).to have_gitlab_http_status(404)
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
            # Notice the filename= is omitted from the disposition; this is because
            # Rails 5 will append this header in send_file
            expect(controller).to receive(:send_file)
                              .with(job.job_artifacts_codequality.file.path,
                                    hash_including(disposition: %Q(attachment; filename*=UTF-8''#{filename}))).and_call_original

            download_artifact(file_type: file_type)
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

          expect(response).to have_gitlab_http_status(302)
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
  end

  describe 'GET raw' do
    subject { get(:raw, params: { namespace_id: project.namespace, project_id: project, job_id: job, path: path }) }

    context 'when the file exists' do
      let(:path) { 'ci_artifacts.txt' }

      shared_examples 'a valid file' do
        it 'serves the file using workhorse' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(send_data).to start_with('artifacts-entry:')

          expect(params.keys).to eq(%w(Archive Entry))
          expect(params['Archive']).to start_with(archive_path)
          # On object storage, the URL can end with a query string
          expect(params['Archive']).to match(/build_artifacts.zip(\?[^?]+)?$/)
          expect(params['Entry']).to eq(Base64.encode64('ci_artifacts.txt'))
        end

        def send_data
          response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]
        end

        def params
          @params ||= begin
            base64_params = send_data.sub(/\Aartifacts\-entry:/, '')
            JSON.parse(Base64.urlsafe_decode64(base64_params))
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
          pipeline.update(ref: 'master',
                          sha: project.commit('master').sha)

          get :latest_succeeded, params: params_from_ref('master')
        end

        it_behaves_like 'redirect to the job'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params: params_from_ref('improve/awesome')
        end

        it_behaves_like 'redirect to the job'
      end

      context 'with branch name and path containing slashes' do
        before do
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params: params_from_ref('improve/awesome', job.name, 'file/README.md')
        end

        it 'redirects' do
          path = file_project_job_artifacts_path(project, job, 'README.md')

          expect(response).to redirect_to(path)
        end
      end
    end
  end
end
