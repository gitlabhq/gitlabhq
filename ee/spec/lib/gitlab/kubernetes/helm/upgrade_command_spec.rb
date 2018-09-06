require 'rails_helper'

describe Gitlab::Kubernetes::Helm::UpgradeCommand do
  let(:application) { build(:clusters_applications_prometheus) }
  let(:files) { { 'ca.pem': 'some file content' } }
  let(:namespace) { ::Gitlab::Kubernetes::Helm::NAMESPACE }
  let(:rbac) { false }
  let(:upgrade_command) do
    described_class.new(
      application.name,
      chart: application.chart,
      files: files,
      rbac: rbac
    )
  end

  subject { upgrade_command }

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
         helm init --client-only >/dev/null
         helm upgrade #{application.name} #{application.chart} --tls --tls-ca-cert /data/helm/#{application.name}/config/ca.pem --tls-cert /data/helm/#{application.name}/config/cert.pem --tls-key /data/helm/#{application.name}/config/key.pem --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
      EOS
    end
  end

  context 'rbac is true' do
    let(:rbac) { true }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm upgrade #{application.name} #{application.chart} --tls --tls-ca-cert /data/helm/#{application.name}/config/ca.pem --tls-cert /data/helm/#{application.name}/config/cert.pem --tls-key /data/helm/#{application.name}/config/key.pem --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'with an application with a repository' do
    let(:ci_runner) { create(:ci_runner) }
    let(:application) { build(:clusters_applications_runner, runner: ci_runner) }
    let(:upgrade_command) do
      described_class.new(
        application.name,
        chart: application.chart,
        files: files,
        rbac: rbac,
        repository: application.repository
      )
    end

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
           helm init --client-only >/dev/null
           helm repo add #{application.name} #{application.repository}
           helm upgrade #{application.name} #{application.chart} --tls --tls-ca-cert /data/helm/#{application.name}/config/ca.pem --tls-cert /data/helm/#{application.name}/config/cert.pem --tls-key /data/helm/#{application.name}/config/key.pem --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'when there is no ca.pem file' do
    let(:files) { { 'file.txt': 'some content' } }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm upgrade #{application.name} #{application.chart} --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  describe '#pod_resource' do
    subject { upgrade_command.pod_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a pod that uses the tiller serviceAccountName' do
        expect(subject.spec.serviceAccountName).to eq('tiller')
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it 'generates a pod that uses the default serviceAccountName' do
        expect(subject.spec.serviceAcccountName).to be_nil
      end
    end
  end

  describe '#config_map_resource' do
    let(:metadata) do
      {
        name: "values-content-configuration-#{application.name}",
        namespace: namespace,
        labels: { name: "values-content-configuration-#{application.name}" }
      }
    end
    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: files) }

    it 'returns a KubeClient resource with config map content for the application' do
      expect(subject.config_map_resource).to eq(resource)
    end
  end

  describe '#rbac?' do
    subject { upgrade_command.rbac? }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it { is_expected.to be_truthy }
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#pod_name' do
    it 'returns the pod name' do
      expect(subject.pod_name).to eq("upgrade-#{application.name}")
    end
  end
end
