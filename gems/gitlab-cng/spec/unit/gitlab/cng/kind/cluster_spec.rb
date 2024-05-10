# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Kind::Cluster do
  subject(:cluster) { described_class.new(ci: ci, name: name, docker_hostname: docker_hostname) }

  let(:ci) { false }
  let(:name) { "gitlab" }
  let(:docker_hostname) { nil }
  let(:tmp_config_path) { File.join(Dir.tmpdir, "kind-config.yml") }
  let(:command_status) { instance_double(Process::Status, success?: true) }
  let(:clusters) { "kind" }

  before do
    allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
    allow(File).to receive(:write).with(tmp_config_path, kind_config_content)

    allow(Open3).to receive(:capture2e).with({}, *%w[
      kind get clusters
    ]).and_return([clusters, command_status])
    allow(Open3).to receive(:capture2e).with({}, *[
      "kind",
      "create",
      "cluster",
      "--name", name,
      "--wait", "10s",
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
                # containerPort below must match the values file:
                #   nginx-ingress.controller.service.nodePorts.http
              - containerPort: 32080
                hostPort: 80
                listenAddress: "0.0.0.0"
                # containerPort below must match the values file:
                #   nginx-ingress.controller.service.nodePorts.gitlab-shell
              - containerPort: 32022
                hostPort: 22
                listenAddress: "0.0.0.0"
      YML
    end

    context "without existing cluster" do
      before do
        allow(Open3).to receive(:capture2e).with({}, *[
          "kubectl", "config", "view", "-o", "jsonpath={.clusters[?(@.name == \"kind-#{name}\")].cluster.server}"
        ]).and_return(["https://127.0.0.1:6443", command_status])
        allow(Open3).to receive(:capture2e).with({}, *%W[
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
            # containerPort below must match the values file:
            #   nginx-ingress.controller.service.nodePorts.http
          - containerPort: 32080
            hostPort: 32080
            listenAddress: "0.0.0.0"
            # containerPort below must match the values file:
            #   nginx-ingress.controller.service.nodePorts.ssh
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
