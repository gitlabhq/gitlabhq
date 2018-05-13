require 'spec_helper'

describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

  subject { described_class.new(project, user, params).execute(access_token) }

  before do
    allow(project).to receive(:feature_available?).and_call_original
  end

  context 'when license has multiple clusters feature' do
    before do
      allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
    end

    context 'when correct params' do
      include_context 'valid cluster create params'

      include_examples 'create cluster service success'
    end

    context 'when invalid params' do
      include_context 'invalid cluster create params'

      include_examples 'create cluster service error'
    end
  end

  context 'when license does not have multiple clusters feature' do
    include_context 'valid cluster create params'

    before do
      allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
    end

    it 'does not create a cluster' do
      expect(ClusterProvisionWorker).not_to receive(:perform_async)
      expect { subject }.to raise_error(ArgumentError).and change { Clusters::Cluster.count }.by(0)
    end
  end
end
