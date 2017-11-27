require 'spec_helper'

describe ClustersFinder do
  let(:project) { create(:project) }
  set(:user) { create(:user) }

  describe '#execute' do
    before do
      create_list(:cluster, 2, :provided_by_gcp, projects: [project])
      project.clusters.last.enabled = false
    end

    subject { described_class.new(project, user, scope).execute }

    context 'when scope is all' do
      let(:scope) { :all }

      it { is_expected.to eq(project.clusters.to_a) }
    end

    context 'when scope is enabled' do
      let(:scope) { :enabled }

      it { is_expected.to eq(project.clusters.enabled.to_a) }
    end

    context 'when scope is disabled' do
      let(:scope) { :disabled }

      it { is_expected.to eq(project.clusters.disabled.to_a) }
    end
  end
end
