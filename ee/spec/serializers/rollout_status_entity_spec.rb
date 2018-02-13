require 'spec_helper'

describe RolloutStatusEntity do
  include KubernetesHelpers

  let(:entity) do
    described_class.new(rollout_status, request: double)
  end

  subject { entity.as_json }

  context 'when kube deployment is valid' do
    let(:rollout_status) { kube_deployment_rollout_status }

    it "exposes status" do
      is_expected.to include(:status)
    end

    it "exposes deployment data" do
      is_expected.to include(:instances, :completion, :is_completed)
    end
  end

  context 'when kube deployment is empty' do
    let(:rollout_status) { empty_deployment_rollout_status }

    it "exposes status" do
      is_expected.to include(:status)
    end

    it "does not expose deployment data" do
      is_expected.not_to include(:instances, :completion, :is_completed)
    end
  end
end
