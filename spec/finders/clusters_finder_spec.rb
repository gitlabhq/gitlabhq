require 'spec_helper'

describe ClustersFinder do
  let(:project) { create(:project) }
  set(:user) { create(:user) }

  describe '#execute' do
    let(:enabled_cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
    let(:disabled_cluster) { create(:cluster, :disabled, :provided_by_gcp, projects: [project]) }

    subject { described_class.new(project, user, scope).execute }

    context 'when scope is all' do
      let(:scope) { :all }

      it { is_expected.to match_array([enabled_cluster, disabled_cluster]) }
    end

    context 'when scope is active' do
      let(:scope) { :active }

      it { is_expected.to match_array([enabled_cluster]) }
    end

    context 'when scope is inactive' do
      let(:scope) { :inactive }

      it { is_expected.to match_array([disabled_cluster]) }
    end
  end
end
