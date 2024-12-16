# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Kind::Cluster do
  let(:config_path) { File.join(Gitlab::Cng::Helpers::Utils.config_dir, "kind-config.yml") }

  let(:kind_config_content) do
    <<~YML
      apiVersion: kind.x-k8s.io/v1alpha4
      kind: Cluster
    YML
  end

  before do
    allow(FileUtils).to receive(:mkdir_p).with(File.join(Dir.home, ".gitlab-cng"))
    allow(File).to receive(:write).with(config_path, kind_config_content)
    allow(File).to receive(:read).with(config_path).and_return(kind_config_content)
  end

  describe "with setup" do
    subject(:cluster) do
      described_class.new(
        ci: ci,
        docker_hostname: docker_hostname,
        host_http_port: 80,
        host_ssh_port: 22,
        host_registry_port: 5000
      )
    end

    let(:ci) { false }
    let(:name) { "gitlab" }
    let(:docker_hostname) { nil }
    let(:command_status) { instance_double(Process::Status, success?: true) }
    let(:clusters) { "kind" }
    let(:helm) { instance_double(Gitlab::Cng::Helm::Client, add_helm_chart: nil, upgrade: nil) }
    let(:http_container_port) { 30080 }
    let(:ssh_container_port) { 31022 }
    let(:registry_container_port) { 32495 }

    before do
      allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
      allow(Gitlab::Cng::Helm::Client).to receive(:new).and_return(helm)

      allow(Open3).to receive(:popen2e).with({}, *%w[
        kind get clusters
      ]).and_return([clusters, command_status])
      allow(Open3).to receive(:popen2e).with({}, *[
        "kind",
        "create",
        "cluster",
        "--name", name,
        "--wait", "30s",
        "--config", config_path
      ]).and_return(["", command_status])

      allow(cluster).to receive(:rand).with(30000..31000).and_return(http_container_port)
      allow(cluster).to receive(:rand).with(31001..32000).and_return(ssh_container_port)
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
                - containerPort: #{http_container_port}
                  hostPort: 80
                  listenAddress: "0.0.0.0"
                - containerPort: #{ssh_container_port}
                  hostPort: 22
                  listenAddress: "0.0.0.0"
                - containerPort: #{registry_container_port}
                  hostPort: 5000
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

        it "creates cluster with ci specific configuration", :aggregate_failures do
          expect { cluster.create }.to output(/Cluster '#{name}' created/).to_stdout
          expect(helm).to have_received(:add_helm_chart).with(
            "metrics-server",
            "https://kubernetes-sigs.github.io/metrics-server/"
          )
          expect(helm).to have_received(:upgrade).with(
            "metrics-server",
            "metrics-server/metrics-server",
            namespace: "kube-system",
            timeout: "1m",
            values: { "args" => ["--kubelet-insecure-tls"] }.to_yaml,
            args: ["--atomic", "--version", "^3.12"]
          )
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
              - containerPort: #{http_container_port}
                hostPort: 80
                listenAddress: "0.0.0.0"
              - containerPort: #{ssh_container_port}
                hostPort: 22
                listenAddress: "0.0.0.0"
              - containerPort: #{registry_container_port}
                hostPort: 5000
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

  describe "#destroy" do
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
        expect { cluster.destroy }.to output(/Destroying cluster 'gitlab'/).to_stdout
        expect(cluster).to have_received(:execute_shell).with(%w[kind delete cluster --name gitlab])
      end
    end

    context "with non existing cluster" do
      before do
        allow(cluster).to receive(:execute_shell).with(%w[kind get clusters]).and_return("non-existing")
      end

      it "deletes cluster" do
        expect { cluster.destroy }.to output(
          match(/Destroying cluster 'gitlab'/).and(match(/Cluster not found, skipping!/))
        ).to_stdout
        expect(cluster).not_to have_received(:execute_shell).with(%w[kind delete cluster --name gitlab])
      end
    end
  end

  describe "#host_port_mapping" do
    let(:http_container_port) { 32080 }
    let(:ssh_container_port) { 32022 }
    let(:registry_container_port) { 32495 }

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
                    - "test"
            extraPortMappings:
              - containerPort: #{http_container_port}
                hostPort: 80
                listenAddress: "0.0.0.0"
              - containerPort: #{ssh_container_port}
                hostPort: 22
                listenAddress: "0.0.0.0"
              - containerPort: #{registry_container_port}
                hostPort: 5000
                listenAddress: "0.0.0.0"
      YML
    end

    it "return correct port mappings" do
      expect(described_class.host_port_mapping(80)).to eq(http_container_port)
      expect(described_class.host_port_mapping(22)).to eq(ssh_container_port)
      expect(described_class.host_port_mapping(5000)).to eq(registry_container_port)
    end
  end
end
