require 'spec_helper'

describe Ci::CreatePipelineService, '#execute' do
  set(:namespace) { create(:namespace, plan: :gold_plan) }
  set(:project) { create(:project, :repository, namespace: namespace) }
  set(:user) { create(:user) }

  let(:service) do
    params = { ref: 'master',
               before: '00000000',
               after: project.commit.id,
               commits: [{ message: 'some commit' }] }

    described_class.new(project, user, params)
  end

  before do
    project.add_developer(user)
    stub_ci_pipeline_to_return_yaml_file
  end

  describe 'CI/CD Quotas / Limits' do
    context 'when there are not limits enabled' do
      it 'enqueues a new pipeline' do
        pipeline = create_pipeline!

        expect(pipeline).to be_persisted
        expect(pipeline).to be_pending
      end
    end

    context 'when pipeline activity limit is exceeded' do
      before do
        namespace.plan.update_column(:active_pipelines_limit, 2)

        create(:ci_pipeline, project: project, status: 'pending')
        create(:ci_pipeline, project: project, status: 'running')
      end

      it 'drops the pipeline and does not process jobs' do
        pipeline = create_pipeline!

        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.statuses).not_to be_empty
        expect(pipeline.statuses).to all(be_created)
        expect(pipeline.activity_limit_exceeded?).to be true
      end
    end

    context 'when pipeline size limit is exceeded' do
      before do
        namespace.plan.update_column(:pipeline_size_limit, 2)
      end

      it 'drops pipeline without creating jobs' do
        pipeline = create_pipeline!

        expect(pipeline).to be_persisted
        expect(pipeline).to be_failed
        expect(pipeline.seeds_size).to be > 2
        expect(pipeline.statuses).to be_empty
        expect(pipeline.size_limit_exceeded?).to be true
      end
    end
  end

  def create_pipeline!
    service.execute(:push)
  end
end
