require 'spec_helper'

describe Projects::JobsController do
  include ApiHelpers

  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

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
