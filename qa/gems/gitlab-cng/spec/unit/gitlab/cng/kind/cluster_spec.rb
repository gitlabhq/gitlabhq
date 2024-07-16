# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Kind::Cluster do
  describe "with setup" do
    subject(:cluster) do
      described_class.new(
        ci: ci,
        name: name,
        docker_hostname: docker_hostname,
        host_http_port: 32080,
        host_ssh_port: 32022
      )
    end

    let(:ci) { false }
    let(:name) { "gitlab" }
    let(:docker_hostname) { nil }
    let(:tmp_config_path) { File.join("/tmp", "kind-config.yml") }
    let(:command_status) { instance_double(Process::Status, success?: true) }
    let(:clusters) { "kind" }

    before do
      allow(Gitlab::Cng::Helpers::Utils).to receive(:tmp_dir).and_return("/tmp")
      allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
      allow(File).to receive(:write).with(tmp_config_path, kind_config_content)

      allow(Open3).to receive(:popen2e).with({}, *%w[
        kind get clusters
      ]).and_return([clusters, command_status])
      allow(Open3).to receive(:popen2e).with({}, *[
        "kind",
        "create",
        "cluster",
        "--name", name,
        "--wait", "30s",
        "--config", tmp_config_path
      ]).and_return(["", command_status])
    end

    context "with ci specific setup" do
      let(:ci) { true }
      let(:docker_hostname) { "docker" }

      let(:kind_config_content) do
        <<~YML
          apiVersion: kind.x-k8s.io/v1alpha4
          kind: Cluster
          networking:
            apiServerAddress: "0.0.0.0"
          nodes:
            - role: control-plane
              kubeadmConfigPatches:
                - |
                  kind: InitConfiguration
                  nodeRegistration:
                    kubeletExtraArgs:
                      node-labels: "ingress-ready=true"
                - |
                  kind: ClusterConfiguration
                  apiServer:
                    certSANs:
                      - "#{docker_hostname}"
              extraPortMappings:
                - containerPort: 32080
                  hostPort: 32080
                  listenAddress: "0.0.0.0"
                - containerPort: 32022
                  hostPort: 32022
                  listenAddress: "0.0.0.0"
        YML
      end

      context "without existing cluster" do
        before do
          allow(Open3).to receive(:popen2e).with({}, *[
            "kubectl", "config", "view", "-o", "jsonpath={.clusters[?(@.name == \"kind-#{name}\")].cluster.server}"
          ]).and_return(["https://127.0.0.1:6443", command_status])
          allow(Open3).to receive(:popen2e).with({}, *%W[
            kubectl config set-cluster kind-#{name} --server=https://#{docker_hostname}:6443
          ]).and_return(["", command_status])
        end

        it "creates cluster with ci specific configuration" do
          expect { cluster.create }.to output(/Cluster '#{name}' created/).to_stdout
        end
      end
    end

    context "without ci specific setup" do
      let(:ci) { false }
      let(:docker_hostname) { nil }

      let(:kind_config_content) do
        <<~YML
          kind: Cluster
          apiVersion: kind.x-k8s.io/v1alpha4
          nodes:
          - role: control-plane
            kubeadmConfigPatches:
              - |
                kind: InitConfiguration
                nodeRegistration:
                  kubeletExtraArgs:
                    node-labels: "ingress-ready=true"
            extraPortMappings:
              - containerPort: 32080
                hostPort: 32080
                listenAddress: "0.0.0.0"
              - containerPort: 32022
                hostPort: 32022
                listenAddress: "0.0.0.0"
        YML
      end

      context "with already created cluster" do
        let(:clusters) { "kind\n#{name}" }

        it "skips clusters creation" do
          expect { cluster.create }.to output(/cluster '#{name}' already exists, skipping!/).to_stdout
        end
      end

      context "without existing cluster" do
        it "creates cluster with default config" do
          expect { cluster.create }.to output(/Cluster '#{name}' created/).to_stdout
        end
      end

      context "with command failure" do
        let(:command_status) { instance_double(Process::Status, success?: false) }

        it "exits on command failures" do
          expect do
            expect { cluster.create }.to output.to_stdout
          end.to raise_error(SystemExit)
        end
      end
    end
  end

  describe "with cleanup" do
    subject(:cluster) { described_class }

    before do
      allow(cluster).to receive(:execute_shell)
      allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
    end

    context "with existing cluster" do
      before do
        allow(cluster).to receive(:execute_shell).with(%w[kind get clusters]).and_return("gitlab")
      end

      it "deletes cluster" do
        expect { cluster.destroy("gitlab") }.to output(/Destroying cluster 'gitlab'/).to_stdout
        expect(cluster).to have_received(:execute_shell).with(%w[kind delete cluster --name gitlab])
      end
    end

    context "with non existing cluster" do
      before do
        allow(cluster).to receive(:execute_shell).with(%w[kind get clusters]).and_return("non-existing")
      end

      it "deletes cluster" do
        expect { cluster.destroy("gitlab") }.to output(
          match(/Destroying cluster 'gitlab'/).and(match(/Cluster not found, skipping!/))
        ).to_stdout
        expect(cluster).not_to have_received(:execute_shell).with(%w[kind delete cluster --name gitlab])
      end
    end
  end
end
