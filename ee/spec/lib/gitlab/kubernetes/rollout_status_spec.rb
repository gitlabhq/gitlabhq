require 'spec_helper'

describe Gitlab::Kubernetes::RolloutStatus do
  include KubernetesHelpers

  let(:track) { nil }
  let(:specs) { specs_all_finished }
  let(:specs_none) { [] }

  let(:pods) do
    create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: "canary")
  end

  let(:specs_all_finished) do
    [
      kube_deployment(name: 'one'),
      kube_deployment(name: 'two', track: track)
    ]
  end

  let(:specs_half_finished) do
    [
      kube_deployment(name: 'one'),
      kube_deployment(name: 'two', track: track)
    ]
  end

  subject(:rollout_status) { described_class.from_deployments(*specs, pods: pods) }

  describe '#deployments' do
    it 'stores the deployments' do
      expect(rollout_status.deployments).to be_kind_of(Array)
      expect(rollout_status.deployments.size).to eq(2)
      expect(rollout_status.deployments.first).to be_kind_of(::Gitlab::Kubernetes::Deployment)
    end
  end

  describe '#instances' do
    context 'for stable track' do
      let(:track) { "any" }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: "any")
      end

      it 'stores the union of deployment instances' do
        expected = [
          { status: 'running', tooltip: 'two (two) Running', track: 'any', stable: false },
          { status: 'running', tooltip: 'two (two) Running', track: 'any', stable: false },
          { status: 'running', tooltip: 'two (two) Running', track: 'any', stable: false },
          { status: 'running', tooltip: 'one (one) Running', track: 'stable', stable: true },
          { status: 'running', tooltip: 'one (one) Running', track: 'stable', stable: true },
          { status: 'running', tooltip: 'one (one) Running', track: 'stable', stable: true }
        ]

        expect(rollout_status.instances).to eq(expected)
      end
    end

    context 'for stable track' do
      let(:track) { 'canary' }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: track)
      end

      it 'stores the union of deployment instances' do
        expected = [
          { status: 'running', tooltip: 'two (two) Running', track: 'canary', stable: false },
          { status: 'running', tooltip: 'two (two) Running', track: 'canary', stable: false },
          { status: 'running', tooltip: 'two (two) Running', track: 'canary', stable: false },
          { status: 'running', tooltip: 'one (one) Running', track: 'stable', stable: true },
          { status: 'running', tooltip: 'one (one) Running', track: 'stable', stable: true },
          { status: 'running', tooltip: 'one (one) Running', track: 'stable', stable: true }
        ]

        expect(rollout_status.instances).to eq(expected)
      end
    end
  end

  describe '#completion' do
    subject { rollout_status.completion }

    context 'when all instances are finished' do
      it { is_expected.to eq(100) }
    end

    context 'when half of the instances are finished' do
      let(:track) { "canary" }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: track, status: "Pending")
      end

      let(:specs) { specs_half_finished }

      it { is_expected.to eq(50) }
    end
  end

  describe '#complete?' do
    subject { rollout_status.complete? }

    context 'when all instances are finished' do
      it { is_expected.to be_truthy }
    end

    context 'when half of the instances are finished' do
      let(:track) { "canary" }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: track, status: "Pending")
      end

      let(:specs) { specs_half_finished }

      it { is_expected.to be_falsy}
    end
  end

  describe '#not_found?' do
    context 'when the specs are passed' do
      it { is_expected.not_to be_not_found }
    end

    context 'when list of specs is empty' do
      let(:specs) { specs_none }

      it { is_expected.to be_not_found }
    end
  end

  describe '#found?' do
    context 'when the specs are passed' do
      it { is_expected.to be_found }
    end

    context 'when list of specs is empty' do
      let(:specs) { specs_none }

      it { is_expected.not_to be_found }
    end
  end

  describe '.loading' do
    subject { described_class.loading }

    it { is_expected.to be_loading }
  end

  def create_pods(name:, count:, track: nil, status: 'Running' )
    Array.new(count, kube_pod(name: name, status: status, track: track))
  end
end
