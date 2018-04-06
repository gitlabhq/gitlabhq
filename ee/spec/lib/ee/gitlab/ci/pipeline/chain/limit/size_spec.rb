require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Chain::Limit::Size do
  set(:namespace) { create(:namespace, plan: :gold_plan) }
  set(:project) { create(:project, :repository, namespace: namespace) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline_with_one_job, project: project,
                                     ref: 'master')
  end

  let(:command) do
    double('command', project: project,
                      current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline size limit is exceeded' do
    before do
      project.namespace.plan.update_column(:pipeline_size_limit, 1)

      step.perform!
    end

    let(:pipeline) do
      config = { rspec: { script: 'rspec' },
                 spinach: { script: 'spinach' } }

      create(:ci_pipeline, project: project, config: config)
    end

    context 'when saving incomplete pipelines' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: true)
      end

      it 'drops the pipeline' do
        expect(pipeline.reload).to be_failed
      end

      it 'persists the pipeline' do
        expect(pipeline).to be_persisted
      end

      it 'breaks the chain' do
        expect(step.break?).to be true
      end

      it 'sets a valid failure reason' do
        expect(pipeline.size_limit_exceeded?).to be true
      end

      it 'appends validation error' do
        expect(pipeline.errors.to_a)
          .to include 'Pipeline size limit exceeded by 1 job!'
      end
    end

    context 'when not saving incomplete pipelines' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: false)
      end

      it 'does not drop the pipeline' do
        expect(pipeline).not_to be_failed
      end

      it 'breaks the chain' do
        expect(step.break?).to be true
      end
    end
  end

  context 'when pipeline size limit is not exceeded' do
    before do
      step.perform!
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'does not persist the pipeline' do
      expect(pipeline).not_to be_persisted
    end
  end
end
