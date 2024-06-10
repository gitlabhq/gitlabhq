# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers -- allows to reuse many of the mock definitions, with less helpers a lot more value duplication would occur
RSpec.describe Gitlab::Cng::Deployment::Installation, :aggregate_failures do
  describe "with setup" do
    subject(:installation) do
      described_class.new(
        "gitlab",
        configuration: configuration,
        namespace: "gitlab",
        ci: ci,
        gitlab_domain: gitlab_domain,
        timeout: "10m",
        chart_sha: chart_sha
      )
    end

    let(:config_values) { { configuration_specific: true } }
    let(:gitlab_domain) { "127.0.0.1.nip.io" }
    let(:chart_sha) { nil }
    let(:chart_reference) { "chart-reference" }

    let(:kubeclient) do
      instance_double(Gitlab::Cng::Kubectl::Client, create_namespace: "", create_resource: "", execute: "")
    end

    let(:helmclient) do
      instance_double(Gitlab::Cng::Helm::Client, add_helm_chart: chart_reference, upgrade: nil)
    end

    let(:configuration) do
      instance_double(
        Gitlab::Cng::Deployment::Configurations::Kind,
        run_pre_deployment_setup: nil,
        run_post_deployment_setup: nil,
        values: config_values,
        gitlab_url: "http://gitlab.#{gitlab_domain}"
      )
    end

    let(:env) do
      {
        "QA_EE_LICENSE" => "license",
        "CI_PROJECT_DIR" => File.expand_path("../../../../fixture", __dir__),
        "CI_COMMIT_SHA" => "0acb5ee6db0860436fafc2c31a2cd87849c51aa3",
        "CI_COMMIT_SHORT_SHA" => "0acb5ee6db08"
      }
    end

    let(:values_yml) do
      {
        global: {
          hosts: {
            domain: gitlab_domain,
            https: false
          },
          ingress: {
            configureCertmanager: false,
            tls: {
              enabled: false
            }
          },
          appConfig: {
            applicationSettingsCacheSeconds: 0
          },
          extraEnv: {
            GITLAB_LICENSE_MODE: "test",
            CUSTOMER_PORTAL_URL: "https://customers.staging.gitlab.com"
          }
        },
        gitlab: {
          "gitlab-exporter": { enabled: false },
          license: { secret: "gitlab-license" }
        },
        redis: { metrics: { enabled: false } },
        prometheus: { install: false },
        certmanager: { install: false },
        "gitlab-runner": { install: false },
        **config_values
      }.deep_stringify_keys.to_yaml
    end

    before do
      allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
      allow(Gitlab::Cng::Kubectl::Client).to receive(:new).with("gitlab").and_return(kubeclient)
      allow(Gitlab::Cng::Helm::Client).to receive(:new).and_return(helmclient)
      allow(Gitlab::Cng::Deployment::Configurations::Kind).to receive(:new).and_return(configuration)

      allow(installation).to receive(:execute_shell)
    end

    around do |example|
      ClimateControl.modify(env) { example.run }
    end

    context "without ci" do
      let(:ci) { false }

      it "runs setup and helm deployment" do
        expect { installation.create }.to output(/Creating CNG deployment 'gitlab'/).to_stdout

        expect(helmclient).to have_received(:add_helm_chart).with(nil)
        expect(helmclient).to have_received(:upgrade).with(
          "gitlab",
          chart_reference,
          namespace: "gitlab",
          timeout: "10m",
          values: values_yml,
          args: []
        )

        expect(kubeclient).to have_received(:create_namespace)
        expect(kubeclient).to have_received(:create_resource).with(
          Gitlab::Cng::Kubectl::Resources::Secret.new("gitlab-license", "license", "license")
        )
        expect(configuration).to have_received(:run_pre_deployment_setup)
        expect(configuration).to have_received(:run_post_deployment_setup)
      end
    end

    context "with ci and specific sha" do
      let(:ci) { true }
      let(:chart_sha) { "sha" }

      it "runs helm install with correctly merged values and component versions" do
        expect { installation.create }.to output(/Creating CNG deployment 'gitlab'/).to_stdout

        expect(helmclient).to have_received(:add_helm_chart).with(chart_sha)
        expect(helmclient).to have_received(:upgrade).with(
          "gitlab",
          chart_reference,
          namespace: "gitlab",
          timeout: "10m",
          values: values_yml,
          # rubocop:disable Layout/LineLength -- fitting the args in to 120 would make the definition quite unreadable
          args: %W[
            --set gitlab.gitaly.image.repository=registry.gitlab.com/gitlab-org/build/cng-mirror/gitaly
            --set gitlab.gitaly.image.tag=7aa06a578d76bdc294ee8e9acb4f063e7d9f1d5f
            --set gitlab.gitlab-shell.image.repository=registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-shell
            --set gitlab.gitlab-shell.image.tag=v14.35.0
            --set gitlab.migrations.image.repository=registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-toolbox-ee
            --set gitlab.migrations.image.tag=#{env['CI_COMMIT_SHA']}
            --set gitlab.toolbox.image.repository=registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-toolbox-ee
            --set gitlab.toolbox.image.tag=#{env['CI_COMMIT_SHA']}
            --set gitlab.sidekiq.annotations.commit=#{env['CI_COMMIT_SHORT_SHA']}
            --set gitlab.sidekiq.image.repository=registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-sidekiq-ee
            --set gitlab.sidekiq.image.tag=#{env['CI_COMMIT_SHA']}
            --set gitlab.webservice.annotations.commit=#{env['CI_COMMIT_SHORT_SHA']}
            --set gitlab.webservice.image.repository=registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-webservice-ee
            --set gitlab.webservice.image.tag=#{env['CI_COMMIT_SHA']}
            --set gitlab.webservice.workhorse.image=registry.gitlab.com/gitlab-org/build/cng-mirror/gitlab-workhorse-ee
            --set gitlab.webservice.workhorse.tag=#{env['CI_COMMIT_SHA']}
          ]
          # rubocop:enable Layout/LineLength
        )
      end
    end
  end

  describe "with cleanup" do
    let(:installation) { described_class }

    let(:helm) { instance_double(Gitlab::Cng::Helm::Client, uninstall: nil) }
    let(:kubeclient) { instance_double(Gitlab::Cng::Kubectl::Client, delete_resource: "") }
    let(:cleanup_configuration) do
      instance_double(
        Gitlab::Cng::Deployment::Configurations::Cleanup::Kind,
        kubeclient: kubeclient,
        namespace: "gitlab",
        run: nil
      )
    end

    before do
      allow(Gitlab::Cng::Helm::Client).to receive(:new).and_return(helm)
      allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
    end

    context "with existing release" do
      before do
        allow(helm).to receive(:status).with("gitlab", namespace: "gitlab").and_return("status")
      end

      it "performs cleanup" do
        expect { installation.uninstall("gitlab", cleanup_configuration: cleanup_configuration, timeout: "10m") }.to(
          output(match(/Performing full deployment cleanup/).and(match(/Removing license secret/))).to_stdout
        )
        expect(helm).to have_received(:uninstall).with("gitlab", namespace: "gitlab", timeout: "10m")
        expect(kubeclient).to have_received(:delete_resource).with("secret", "gitlab-license")
        expect(kubeclient).to have_received(:delete_resource).with("namespace", "gitlab")
        expect(cleanup_configuration).to have_received(:run)
      end
    end

    context "without existing release" do
      before do
        allow(helm).to receive(:status).with("gitlab", namespace: "gitlab").and_return(nil)
      end

      it "skips cleanup" do
        expect { installation.uninstall("gitlab", cleanup_configuration: cleanup_configuration, timeout: "10m") }.to(
          output(/Helm release 'gitlab' not found, skipping/).to_stdout
        )
        expect(helm).not_to have_received(:uninstall)
        expect(kubeclient).not_to have_received(:delete_resource)
        expect(cleanup_configuration).not_to have_received(:run)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
