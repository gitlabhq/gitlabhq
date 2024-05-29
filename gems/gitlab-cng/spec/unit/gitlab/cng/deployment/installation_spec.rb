# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::Installation, :aggregate_failures do
  subject(:installation) do
    described_class.new(
      "gitlab",
      configuration: "kind",
      namespace: "gitlab",
      ci: ci
    )
  end

  let(:stdin) { StringIO.new }
  let(:config_values) { { configuration_specific: true } }

  let(:ip) { instance_double(Addrinfo, ipv4_private?: true, ip_address: "127.0.0.1") }

  let(:kubeclient) do
    instance_double(Gitlab::Cng::Kubectl::Client, create_namespace: "", create_resource: "", execute: "")
  end

  let(:configuration) do
    instance_double(
      Gitlab::Cng::Deployment::Configurations::Kind,
      run_pre_deployment_setup: nil,
      run_post_deployment_setup: nil,
      values: config_values,
      gitlab_url: "http://gitlab.#{ip.ip_address}.nip.io"
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
          domain: "#{ip.ip_address}.nip.io",
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
    allow(Gitlab::Cng::Deployment::Configurations::Kind).to receive(:new).and_return(configuration)

    allow(installation).to receive(:execute_shell)
    allow(Socket).to receive(:ip_address_list).and_return([ip])
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  context "without ci" do
    let(:ci) { false }

    it "runs setup and helm deployment" do
      expect { installation.create }.to output(/Creating CNG deployment 'gitlab' using 'kind' configuration/).to_stdout

      expect(Gitlab::Cng::Deployment::Configurations::Kind).to have_received(:new).with(
        "gitlab",
        kubeclient,
        ci,
        "#{ip.ip_address}.nip.io"
      )
      expect(installation).to have_received(:execute_shell).with(
        %w[helm repo add gitlab https://charts.gitlab.io],
        stdin_data: nil
      )
      expect(installation).to have_received(:execute_shell).with(
        %w[helm repo add gitlab https://charts.gitlab.io],
        stdin_data: nil
      )
      expect(installation).to have_received(:execute_shell).with(
        %w[helm repo update gitlab],
        stdin_data: nil
      )
      expect(installation).to have_received(:execute_shell).with(
        %w[
          helm upgrade
          --install gitlab gitlab/gitlab
          --namespace gitlab
          --timeout 5m
          --wait
          --values -
        ],
        stdin_data: values_yml
      )

      expect(kubeclient).to have_received(:create_namespace)
      expect(kubeclient).to have_received(:create_resource).with(
        Gitlab::Cng::Kubectl::Resources::Secret.new("gitlab-license", "license", "license")
      )
      expect(configuration).to have_received(:run_pre_deployment_setup)
      expect(configuration).to have_received(:run_post_deployment_setup)
    end
  end

  context "with ci" do
    let(:ci) { true }

    it "runs helm install with correctly merged values and component versions" do
      expect { installation.create }.to output(/Creating CNG deployment 'gitlab' using 'kind' configuration/).to_stdout

      expect(installation).to have_received(:execute_shell).with(
        %W[
          helm upgrade
          --install gitlab gitlab/gitlab
          --namespace gitlab
          --timeout 5m
          --wait
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
          --values -
        ],
        stdin_data: values_yml
      )
    end
  end
end
