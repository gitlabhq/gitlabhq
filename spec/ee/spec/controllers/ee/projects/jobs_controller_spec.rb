require 'spec_helper'

describe Projects::JobsController do
  include ApiHelpers
  include HttpIOHelpers

  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  describe 'GET trace.json' do
    context 'when trace artifact is in ObjectStorage' do
      let!(:job) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      before do
        allow_any_instance_of(JobArtifactUploader).to receive(:file_storage?) { false }
        allow_any_instance_of(JobArtifactUploader).to receive(:url) { remote_trace_url }
        allow_any_instance_of(JobArtifactUploader).to receive(:size) { remote_trace_size }
      end

      context 'when there are no network issues' do
        before do
          stub_remote_trace_ok

          get_trace
        end

        it 'returns a trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq job.id
          expect(json_response['status']).to eq job.status
          expect(json_response['html']).to eq(job.trace.html)
        end
      end

      context 'when there is a network issue' do
        before do
          stub_remote_trace_ng
        end

        it 'returns a trace' do
          expect { get_trace }.to raise_error(Gitlab::Ci::Trace::HttpIO::FailedToGetChunkError)
        end
      end
    end

    def get_trace
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id,
                  format: :json
    end
  end

  describe 'GET raw' do
    subject do
      post :raw, namespace_id: project.namespace,
                 project_id: project,
                 id: job.id
    end

    context 'when the trace artifact is in ObjectStorage' do
      let!(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      before do
        allow_any_instance_of(JobArtifactUploader).to receive(:file_storage?) { false }
      end

      it 'redirect to the trace file url' do
        expect(subject).to redirect_to(job.job_artifacts_trace.file.url)
      end
    end
  end
end
