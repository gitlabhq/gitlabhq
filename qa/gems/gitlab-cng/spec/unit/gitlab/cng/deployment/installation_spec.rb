# frozen_string_literal: true

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
        chart_sha: chart_sha,
        env: ["RAILS_ENV_VAR=val"],
        retry: retry_attempts
      )
    end

    let(:config_values) { { configuration_specific: true } }
    let(:gitlab_domain) { "127.0.0.1.nip.io" }
    let(:chart_sha) { nil }
    let(:chart_reference) { "chart-reference" }
    let(:ci) { false }
    let(:retry_attempts) { 0 }

    let(:kubeclient) do
      instance_double(Gitlab::Cng::Kubectl::Client, create_namespace: "", create_resource: "", execute: "")
    end

    let(:helmclient) do
      instance_double(Gitlab::Cng::Helm::Client, add_gitlab_helm_chart: chart_reference, upgrade: nil)
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

    let(:resources_values) do
      Gitlab::Cng::Deployment::ResourcePresets.resource_values(
        ci ? Gitlab::Cng::Deployment::ResourcePresets::HIGH : Gitlab::Cng::Deployment::ResourcePresets::DEFAULT
      )
    end

    let(:expected_values_yml) do
      {
        global: {
          common: "val",
          extraEnv: {
            GITLAB_LICENSE_MODE: "test",
            CUSTOMER_PORTAL_URL: "https://customers.staging.gitlab.com",
            RAILS_ENV_VAR: "val"
          }
        },
        gitlab: {
          license: { secret: "gitlab-license" }
        },
        **config_values
      }.deep_merge(resources_values).deep_stringify_keys.to_yaml
    end

    before do
      allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
      allow(Gitlab::Cng::Kubectl::Client).to receive(:new).with("gitlab").and_return(kubeclient)
      allow(Gitlab::Cng::Helm::Client).to receive(:new).and_return(helmclient)
      allow(Gitlab::Cng::Deployment::Configurations::Kind).to receive(:new).and_return(configuration)
      allow(Gitlab::Cng::Deployment::DefaultValues).to receive(:common_values).with(gitlab_domain).and_return({
        global: { common: "val" }
      })

      allow(installation).to receive(:execute_shell)
    end

    around do |example|
      ClimateControl.modify({ "QA_EE_LICENSE" => "license" }) { example.run }
    end

    context "with deployment failure" do
      let(:warn_events) do
        [
          {
            involvedObject: {
              kind: "Pod",
              name: "gitlab-webservice-default"
            },
            kind: "Event",
            message: "failed to sync secret cache: timed out waiting for the condition",
            reason: "FailedMount",
            type: "Warning"
          },
          {
            involvedObject: {
              kind: "HorizontalPodAutoscaler",
              name: "gitlab-webservice-default"
            },
            kind: "Event",
            message: "failed to get cpu usage",
            reason: "FailedGetResourceMetric",
            type: "Warning"
          }
        ]
      end

      let(:valid_event) { warn_events.first }
      let(:removed_event) { warn_events.last }

      before do
        allow(helmclient).to receive(:upgrade).and_raise(Gitlab::Cng::Helm::Client::Error, "error")
        allow(kubeclient).to receive(:events).with(json_format: true).and_return({ items: warn_events }.to_json)
      end

      context "without retry" do
        it "automatically prints warning events and troubleshooting info" do
          expect { expect { installation.create }.to raise_error(SystemExit) }.to output(
            match("#{valid_event[:involvedObject][:kind]}/#{valid_event[:involvedObject][:name]}")
            .and(match(valid_event[:message]))
            .and(match(/For more information on troubleshooting failures, see: \S+/))
          ).to_stdout
        end

        it "removes metrics related warning events" do
          expect { expect { installation.create }.to raise_error(SystemExit) }.not_to output(
            match("#{removed_event[:involvedObject][:kind]}/#{removed_event[:involvedObject][:name]}")
          ).to_stdout
        end
      end

      context "with retry" do
        let(:retry_attempts) { 1 }

        it "retries deployment" do
          expect { expect { installation.create }.to raise_error(SystemExit) }.to output.to_stdout
          expect(helmclient).to have_received(:upgrade).with(
            "gitlab",
            chart_reference,
            hash_including(args: ["--atomic"])
          )
          expect(helmclient).to have_received(:upgrade).with(
            "gitlab",
            chart_reference,
            hash_including(args: [])
          )
        end
      end
    end

    context "with successful deployment" do
      it "runs setup and helm deployment" do
        expect { installation.create }.to output(/Creating CNG deployment 'gitlab'/).to_stdout

        expect(helmclient).to have_received(:add_gitlab_helm_chart).with(nil)
        expect(helmclient).to have_received(:upgrade).with(
          "gitlab",
          chart_reference,
          namespace: "gitlab",
          timeout: "10m",
          values: expected_values_yml,
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

    context "with successful deployment on CI" do
      let(:ci) { true }
      let(:chart_sha) { "sha" }
      let(:ci_components) { { "gitlab.gitaly.image.repository" => "repo", "gitlab.gitaly.image.tag" => "tag" } }

      before do
        allow(Gitlab::Cng::Deployment::DefaultValues).to receive(:component_ci_versions).and_return(ci_components)
      end

      it "runs helm install with correctly merged values and component versions" do
        expect { installation.create }.to output(/Creating CNG deployment 'gitlab'/).to_stdout

        expect(helmclient).to have_received(:add_gitlab_helm_chart).with(chart_sha)
        expect(helmclient).to have_received(:upgrade).with(
          "gitlab",
          chart_reference,
          namespace: "gitlab",
          timeout: "10m",
          values: expected_values_yml,
          args: ci_components.flat_map { |k, v| ["--set", "#{k}=#{v}"] }
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
