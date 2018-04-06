require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Quota::Size do
  set(:namespace) { create(:namespace, plan: :gold_plan) }
  set(:project) { create(:project, :repository, namespace: namespace) }

  let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }
  let(:limit) { described_class.new(namespace, pipeline) }

  shared_context 'pipeline size limit exceeded' do
    let(:pipeline) do
      config = { rspec: { script: 'rspec' },
                 spinach: { script: 'spinach' } }

      build(:ci_pipeline, project: project, config: config)
    end

    before do
      namespace.plan.update_column(:pipeline_size_limit, 1)
    end
  end

  shared_context 'pipeline size limit not exceeded' do
    let(:pipeline) { build(:ci_pipeline_with_one_job, project: project) }

    before do
      namespace.plan.update_column(:pipeline_size_limit, 2)
    end
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        namespace.plan.update_column(:pipeline_size_limit, 10)
      end

      it 'is enabled' do
        expect(limit).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        namespace.plan.update_column(:pipeline_size_limit, 0)
      end

      it 'is not enabled' do
        expect(limit).not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'pipeline size limit exceeded'

      it 'is exceeded' do
        expect(limit).to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'pipeline size limit not exceeded'

      it 'is not exceeded' do
        expect(limit).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'pipeline size limit exceeded'

      it 'returns infor about pipeline size limit exceeded' do
        expect(limit.message)
          .to eq "Pipeline size limit exceeded by 1 job!"
      end
    end
  end
end
