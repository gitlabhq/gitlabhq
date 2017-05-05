require 'spec_helper'

describe Projects::ArtifactsController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
            project: project,
            sha: project.commit.sha,
            ref: project.default_branch,
            status: 'success')
  end

  let(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    project.team << [user, :developer]

    sign_in(user)
  end

  describe 'GET download' do
    it 'sends the artifacts file' do
      expect(controller).to receive(:send_file).with(build.artifacts_file.path, disposition: 'attachment').and_call_original

      get :download, namespace_id: project.namespace, project_id: project, build_id: build
    end
  end

  describe 'GET browse' do
    context 'when the directory exists' do
      it 'renders the browse view' do
        get :browse, namespace_id: project.namespace, project_id: project, build_id: build, path: 'other_artifacts_0.1.2'

        expect(response).to render_template('projects/artifacts/browse')
      end
    end

    context 'when the directory does not exist' do
      it 'responds Not Found' do
        get :browse, namespace_id: project.namespace, project_id: project, build_id: build, path: 'unknown'

        expect(response).to be_not_found
      end
    end
  end

  describe 'GET file' do
    context 'when the file exists' do
      it 'renders the file view' do
        get :file, namespace_id: project.namespace, project_id: project, build_id: build, path: 'ci_artifacts.txt'

        expect(response).to render_template('projects/artifacts/file')
      end
    end

    context 'when the file does not exist' do
      it 'responds Not Found' do
        get :file, namespace_id: project.namespace, project_id: project, build_id: build, path: 'unknown'

        expect(response).to be_not_found
      end
    end
  end

  describe 'GET raw' do
    context 'when the file exists' do
      it 'serves the file using workhorse' do
        get :raw, namespace_id: project.namespace, project_id: project, build_id: build, path: 'ci_artifacts.txt'

        send_data = response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]

        expect(send_data).to start_with('artifacts-entry:')

        base64_params = send_data.sub(/\Aartifacts\-entry:/, '')
        params = JSON.parse(Base64.urlsafe_decode64(base64_params))

        expect(params.keys).to eq(%w(Archive Entry))
        expect(params['Archive']).to end_with('build_artifacts.zip')
        expect(params['Entry']).to eq(Base64.encode64('ci_artifacts.txt'))
      end
    end

    context 'when the file does not exist' do
      it 'responds Not Found' do
        get :raw, namespace_id: project.namespace, project_id: project, build_id: build, path: 'unknown'

        expect(response).to be_not_found
      end
    end
  end

  describe 'GET latest_succeeded' do
    def params_from_ref(ref = pipeline.ref, job = build.name, path = 'browse')
      {
        namespace_id: project.namespace,
        project_id: project,
        ref_name_and_path: File.join(ref, path),
        job: job
      }
    end

    context 'cannot find the build' do
      shared_examples 'not found' do
        it { expect(response).to have_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get :latest_succeeded, params_from_ref('TAIL', build.name)
        end

        it_behaves_like 'not found'
      end

      context 'has no such build' do
        before do
          get :latest_succeeded, params_from_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end

      context 'has no path' do
        before do
          get :latest_succeeded, params_from_ref(pipeline.sha, build.name, '')
        end

        it_behaves_like 'not found'
      end
    end

    context 'found the build and redirect' do
      shared_examples 'redirect to the build' do
        it 'redirects' do
          path = browse_namespace_project_build_artifacts_path(
            project.namespace,
            project,
            build)

          expect(response).to redirect_to(path)
        end
      end

      context 'with regular branch' do
        before do
          pipeline.update(ref: 'master',
                          sha: project.commit('master').sha)

          get :latest_succeeded, params_from_ref('master')
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params_from_ref('improve/awesome')
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with branch name and path containing slashes' do
        before do
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get :latest_succeeded, params_from_ref('improve/awesome', build.name, 'file/README.md')
        end

        it 'redirects' do
          path = file_namespace_project_build_artifacts_path(
            project.namespace,
            project,
            build,
            'README.md')

          expect(response).to redirect_to(path)
        end
      end
    end
  end
end
