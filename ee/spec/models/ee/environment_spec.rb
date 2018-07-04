require 'spec_helper'

describe Environment do
  let(:project) { create(:project, :stubbed_repository) }
  let(:environment) { create(:environment, project: project) }

  describe '#pod_names' do
    context 'when environment does not have a rollout status' do
      it 'returns an empty array' do
        expect(environment.pod_names).to eq([])
      end
    end

    context 'when environment has a rollout status' do
      it 'returns the pod_names' do
        pod_name = "pod_1"
        create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project])
        create(:deployment, environment: environment)

        allow_any_instance_of(Gitlab::Kubernetes::RolloutStatus).to receive(:instances)
          .and_return([{ pod_name: pod_name }])

        expect(environment.pod_names).to eq([pod_name])
      end
    end
  end
end
