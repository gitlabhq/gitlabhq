# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::Services::CloudNativePG, :aggregate_failures do
  subject(:service) do
    described_class.new(
      kubeclient: kubeclient,
      helm: helm,
      namespace: namespace,
      cluster_name: cluster_name
    )
  end

  let(:namespace) { "gitlab" }
  let(:cluster_name) { "gitlab-pg" }

  let(:kubeclient) { instance_double(Gitlab::Orchestrator::Kubectl::Client, create_resource: "") }
  let(:helm) do
    instance_double(Gitlab::Orchestrator::Helm::Client, add_helm_chart: nil, upgrade: nil, uninstall: nil)
  end

  before do
    allow(service).to receive(:execute_shell).and_return("")
  end

  describe "attribute readers" do
    it "returns the correct host" do
      expect(service.host).to eq("gitlab-pg-rw.gitlab.svc.cluster.local")
    end

    it "returns the correct password_secret_name" do
      expect(service.password_secret_name).to eq("gitlab-pg-app")
    end

    it "returns the correct password_secret_key" do
      expect(service.password_secret_key).to eq("password")
    end
  end

  describe "#install" do
    before do
      allow(service).to receive(:cluster_ready?).and_return(true)
    end

    it "installs the operator and applies the cluster resource" do
      expect { service.install }.to output(
        match(/Installing CloudNativePG/)
          .and(match(/Adding CNPG Helm chart repo/))
          .and(match(/Installing CNPG operator/))
          .and(match(/Waiting for CNPG operator to become ready/))
          .and(match(/Applying CNPG Cluster resource/))
          .and(match(/Waiting for CNPG cluster to become ready/))
          .and(match(/CNPG cluster is ready/))
      ).to_stdout

      expect(helm).to have_received(:add_helm_chart).with("cnpg", "https://cloudnative-pg.github.io/charts")
      expect(helm).to have_received(:upgrade).with(
        "cnpg-operator", "cnpg/cloudnative-pg",
        namespace: namespace, timeout: "5m", values: "---\n", args: ["--wait"]
      )
      expect(service).to have_received(:execute_shell).with([
        "kubectl", "wait", "deployment",
        "-l", "app.kubernetes.io/instance=cnpg-operator",
        "-n", namespace,
        "--for=condition=Available",
        "--timeout=300s"
      ])
      expect(kubeclient).to have_received(:create_resource).with(
        an_instance_of(Gitlab::Orchestrator::Kubectl::Resources::CustomResource)
      )
    end
  end

  describe "#uninstall" do
    it "deletes the cluster and uninstalls the operator" do
      expect { service.uninstall }.to output(
        match(/Uninstalling CloudNativePG/)
          .and(match(/Deleting CNPG cluster/))
          .and(match(/Uninstalling CNPG operator/))
      ).to_stdout

      expect(service).to have_received(:execute_shell).with(
        [
          "kubectl", "delete", "cluster", cluster_name,
          "-n", namespace,
          "--ignore-not-found=true", "--wait"
        ], raise_on_failure: false
      )
      expect(helm).to have_received(:uninstall).with("cnpg-operator", namespace: namespace, timeout: "5m")
    end

    context "when cluster deletion fails" do
      before do
        allow(service).to receive(:execute_shell)
          .with(
            ["kubectl", "delete", "cluster", cluster_name, "-n", namespace, "--ignore-not-found=true", "--wait"],
            raise_on_failure: false
          )
          .and_raise(Gitlab::Orchestrator::Helpers::Shell::CommandFailure, "delete failed")
      end

      it "logs a warning and continues to uninstall the operator" do
        expect { service.uninstall }.to output(
          match(/CNPG cluster deletion failed: delete failed/)
            .and(match(/Uninstalling CNPG operator/))
        ).to_stdout

        expect(helm).to have_received(:uninstall).with("cnpg-operator", namespace: namespace, timeout: "5m")
      end
    end

    context "when operator uninstall fails" do
      before do
        allow(helm).to receive(:uninstall)
          .and_raise(Gitlab::Orchestrator::Helm::Client::Error, "uninstall failed")
      end

      it "logs a warning and does not raise" do
        expect { service.uninstall }.to output(
          match(/CNPG operator uninstall failed: uninstall failed/)
        ).to_stdout
      end
    end
  end

  describe "cluster_manifest" do
    it "returns the expected manifest structure" do
      manifest = service.send(:cluster_manifest)

      expect(manifest).to eq({
        apiVersion: "postgresql.cnpg.io/v1",
        kind: "Cluster",
        metadata: {
          name: cluster_name,
          namespace: namespace
        },
        spec: {
          instances: 1,
          imageName: "ghcr.io/cloudnative-pg/postgresql:17",
          postgresql: {
            parameters: {
              max_connections: "200"
            }
          },
          bootstrap: {
            initdb: {
              database: "gitlabhq_production",
              owner: "gitlab",
              postInitApplicationSQL: [
                "CREATE EXTENSION IF NOT EXISTS pg_trgm;",
                "CREATE EXTENSION IF NOT EXISTS btree_gist;",
                "CREATE EXTENSION IF NOT EXISTS plpgsql;",
                "CREATE EXTENSION IF NOT EXISTS amcheck;",
                "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
              ]
            }
          },
          storage: {
            size: "5Gi"
          }
        }
      })
    end

    context "with additional databases" do
      subject(:service) do
        described_class.new(
          kubeclient: kubeclient,
          helm: helm,
          namespace: namespace,
          cluster_name: cluster_name,
          additional_databases: [{ name: "openbao", owner: "openbao", password: "s3cret" }]
        )
      end

      it "bootstraps the role and database via postInitSQL without clobbering the base bootstrap" do
        initdb = service.send(:cluster_manifest).dig(:spec, :bootstrap, :initdb)

        expect(initdb).to include(
          database: "gitlabhq_production",
          owner: "gitlab",
          postInitSQL: [
            "CREATE ROLE openbao LOGIN PASSWORD 's3cret';",
            "CREATE DATABASE openbao OWNER openbao;"
          ]
        )
        expect(initdb[:postInitApplicationSQL]).to include("CREATE EXTENSION IF NOT EXISTS pg_trgm;")
      end
    end
  end

  describe "wait_for_cluster" do
    context "when cluster becomes ready" do
      before do
        allow(service).to receive(:execute_shell)
          .with(
            ["kubectl", "get", "cluster", cluster_name, "-n", namespace, "-o", "jsonpath={.status.phase}"],
            raise_on_failure: false
          )
          .and_return("Cluster in healthy state")
      end

      it "completes without error" do
        expect { service.send(:wait_for_cluster) }.to output(
          match(/Waiting for CNPG cluster to become ready/)
            .and(match(/CNPG cluster is ready/))
        ).to_stdout
      end
    end

    context "when cluster does not become ready before timeout" do
      before do
        allow(service).to receive(:execute_shell)
          .with(
            ["kubectl", "get", "cluster", cluster_name, "-n", namespace, "-o", "jsonpath={.status.phase}"],
            raise_on_failure: false
          )
          .and_return("Cluster is being created")
        stub_const("#{described_class}::WAIT_TIMEOUT", 0)
      end

      it "raises a timeout error" do
        expect { service.send(:wait_for_cluster) }.to raise_error(
          RuntimeError, /Timed out waiting for CNPG cluster 'gitlab-pg' to become ready/
        ).and output(/Waiting for CNPG cluster to become ready/).to_stdout
      end
    end

    context "when execute_shell returns an array" do
      before do
        allow(service).to receive(:execute_shell)
          .with(
            ["kubectl", "get", "cluster", cluster_name, "-n", namespace, "-o", "jsonpath={.status.phase}"],
            raise_on_failure: false
          )
          .and_return(["Cluster in healthy state", instance_double(Process::Status, success?: true)])
      end

      it "extracts the first element and detects healthy state" do
        expect { service.send(:wait_for_cluster) }.to output(
          match(/CNPG cluster is ready/)
        ).to_stdout
      end
    end
  end
end
