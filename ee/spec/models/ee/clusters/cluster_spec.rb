require 'spec_helper'

describe Clusters::Cluster do
  it { is_expected.to include_module(HasEnvironmentScope) }

  describe 'validation' do
    subject { cluster.valid? }

    context 'when validates unique_environment_scope' do
      let(:project) { create(:project) }

      before do
        create(:cluster, projects: [project], environment_scope: 'product/*')
      end

      context 'when identical environment scope exists in project' do
        let(:cluster) { build(:cluster, projects: [project], environment_scope: 'product/*') }

        it { is_expected.to be_falsey }
      end

      context 'when identical environment scope does not exist in project' do
        let(:cluster) { build(:cluster, projects: [project], environment_scope: '*') }

        it { is_expected.to be_truthy }
      end

      context 'when identical environment scope exists in different project' do
        let(:project2) { create(:project) }
        let(:cluster) { build(:cluster, projects: [project2], environment_scope: 'product/*') }

        it { is_expected.to be_truthy }
      end
    end
  end
end
