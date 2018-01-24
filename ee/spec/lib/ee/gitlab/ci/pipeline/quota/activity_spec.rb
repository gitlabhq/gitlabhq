require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Quota::Activity do
  set(:namespace) { create(:namespace, plan: :gold_plan) }
  set(:project) { create(:project, namespace: namespace) }

  let(:limit) { described_class.new(namespace, project) }

  shared_context 'pipeline activity limit exceeded' do
    before do
      create(:ci_pipeline, project: project, status: 'created')
      create(:ci_pipeline, project: project, status: 'pending')
      create(:ci_pipeline, project: project, status: 'running')

      namespace.plan.update_column(:active_pipelines_limit, 1)
    end
  end

  shared_context 'pipeline activity limit not exceeded' do
    before do
      namespace.plan.update_column(:active_pipelines_limit, 2)
    end
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        namespace.plan.update_column(:active_pipelines_limit, 10)
      end

      it 'is enabled' do
        expect(limit).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        namespace.plan.update_column(:active_pipelines_limit, 0)
      end

      it 'is not enabled' do
        expect(limit).not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'pipeline activity limit exceeded'

      it 'is exceeded' do
        expect(limit).to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'pipeline activity limit not exceeded'

      it 'is not exceeded' do
        expect(limit).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'pipeline activity limit exceeded'

      it 'returns info about pipeline activity limit exceeded' do
        expect(limit.message)
          .to eq "Active pipelines limit exceeded by 2 pipelines!"
      end
    end
  end
end
