require 'rails_helper'

describe Gitlab::Kubernetes::Helm::UpgradeCommand do
  let(:application) { build(:clusters_applications_prometheus) }
  let(:namespace) { ::Gitlab::Kubernetes::Helm::NAMESPACE }

  subject do
    described_class.new(
      application.name,
      chart: application.chart,
      values: application.values
    )
  end

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
         helm init --client-only >/dev/null
         helm upgrade #{application.name} #{application.chart} --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
      EOS
    end
  end

  context 'with an application with a repository' do
    let(:ci_runner) { create(:ci_runner) }
    let(:application) { build(:clusters_applications_runner, runner: ci_runner) }

    subject do
      described_class.new(
        application.name,
        chart: application.chart,
        values: application.values,
        repository: application.repository
      )
    end

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
           helm init --client-only >/dev/null
           helm repo add #{application.name} #{application.repository}
           helm upgrade #{application.name} #{application.chart} --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  describe '#config_map?' do
    it 'returns true' do
      expect(subject.config_map?).to be_truthy
    end
  end

  describe '#config_map_resource' do
    it 'returns a KubeClient resource with config map content for the application' do
      metadata = {
        name: "values-content-configuration-#{application.name}",
        namespace: namespace,
        labels: { name: "values-content-configuration-#{application.name}" }
      }
      resource = ::Kubeclient::Resource.new(metadata: metadata, data: { values: application.values })

      expect(subject.config_map_resource).to eq(resource)
    end
  end

  describe '#pod_name' do
    it 'returns the pod name' do
      expect(subject.pod_name).to eq("upgrade-#{application.name}")
    end
  end
end
