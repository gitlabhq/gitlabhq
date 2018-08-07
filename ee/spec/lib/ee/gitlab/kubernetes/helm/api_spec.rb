require 'spec_helper'

describe Gitlab::Kubernetes::Helm::Api do
  let(:kubeclient)  { spy }
  let(:namespace)   { spy }
  let(:application) { build(:clusters_applications_prometheus) }

  subject { described_class.new(kubeclient) }

  before do
    allow(Gitlab::Kubernetes::Namespace)
      .to receive(:new)
      .with(Gitlab::Kubernetes::Helm::NAMESPACE, kubeclient)
      .and_return(namespace)
  end

  describe '#get_config_map' do
    it 'ensures the namespace exists before retrieving the config map' do
      expect(namespace).to receive(:ensure_exists!).once

      subject.get_config_map(application.name)
    end

    it 'gets the config map on kubeclient' do
      expect(kubeclient).to receive(:get_config_map)
        .with("example-config-map-name", namespace.name)
        .once

      subject.get_config_map("example-config-map-name")
    end
  end

  describe '#update' do
    let(:command) do
      Gitlab::Kubernetes::Helm::UpgradeCommand.new(
        application.name,
        chart: application.chart,
        files: application.files
      )
    end

    it 'ensures the namespace exists before creating the pod' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(kubeclient).to receive(:create_pod).once.ordered

      subject.update(command)
    end

    it 'updates the config map on kubeclient when one exists' do
      resource = Gitlab::Kubernetes::ConfigMap.new(
        application.name, application.files
      ).generate

      expect(kubeclient).to receive(:update_config_map).with(resource).once

      subject.update(command)
    end
  end
end
