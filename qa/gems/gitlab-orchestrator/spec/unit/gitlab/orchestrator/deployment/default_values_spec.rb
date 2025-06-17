# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::DefaultValues do
  let(:ci_project_dir) { "/builds/dir" }
  let(:ci_commit_sha) { "0acb5ee6db0860436fafc2c31a2cd87849c51aa3" }
  let(:ci_short_sha) { "0acb5ee6db08" }
  let(:image_repository) { "registry.gitlab.com/gitlab-org/build/cng-mirror" }
  let(:gitaly_version) { "7aa06a578d76bdc294ee8e9acb4f063e7d9f1d5f" }
  let(:kas_version) { "7aa06a578d76bdc294ee8e9acb4f063e7d9f1d5f" }
  let(:shell_version) { "14.0.5" }
  let(:image_tags) { {} }

  let(:env) do
    {
      "CI_PROJECT_DIR" => ci_project_dir,
      "CI_COMMIT_SHA" => ci_commit_sha,
      "CI_COMMIT_SHORT_SHA" => ci_short_sha
    }
  end

  let(:memoized_variables) do
    [
      :@ci_project_dir,
      :@gitaly_version,
      :@kas_version,
      :@toolbox_version,
      :@webservice_version,
      :@workhorse_version,
      :@gitlab_shell_version,
      :@sidekiq_version,
      :@registry_version
    ]
  end

  before do
    memoized_variables.each { |variable| described_class.instance_variable_set(variable, nil) }

    allow(File).to receive(:read).with(File.join(ci_project_dir, "GITALY_SERVER_VERSION")).and_return(gitaly_version)
    allow(File).to receive(:read).with(File.join(ci_project_dir, "GITLAB_SHELL_VERSION")).and_return(shell_version)
    allow(File).to receive(:read).with(File.join(ci_project_dir, "GITLAB_KAS_VERSION")).and_return(kas_version)
  end

  around do |example|
    ClimateControl.modify({ **env, **image_tags }) { example.run }
  end

  it "returns correct common values" do
    expect(described_class.common_values("domain")).to eq({
      global: {
        hosts: {
          domain: "domain",
          https: false
        },
        ingress: {
          configureCertmanager: false,
          tls: {
            enabled: false
          }
        },
        appConfig: {
          applicationSettingsCacheSeconds: 0,
          dependencyProxy: {
            enabled: true
          }
        }
      },
      postgresql: {
        metrics: { enabled: false },
        primary: {
          extraEnvVars: [
            { name: "POSTGRESQL_MAX_CONNECTIONS", value: "200" }
          ]
        }
      },
      gitlab: { "gitlab-exporter": { enabled: false } },
      redis: { metrics: { enabled: false } },
      prometheus: { install: false },
      certmanager: { install: false },
      "gitlab-runner": { install: false }
    })
  end

  it "returns correct ci components" do
    expect(described_class.component_ci_versions).to eq({
      "gitlab.gitaly.image.repository" => "#{image_repository}/gitaly",
      "gitlab.gitaly.image.tag" => gitaly_version,
      "gitlab.gitlab-shell.image.repository" => "#{image_repository}/gitlab-shell",
      "gitlab.gitlab-shell.image.tag" => "v#{shell_version}",
      "gitlab.migrations.image.repository" => "#{image_repository}/gitlab-toolbox-ee",
      "gitlab.migrations.image.tag" => ci_commit_sha,
      "gitlab.toolbox.image.repository" => "#{image_repository}/gitlab-toolbox-ee",
      "gitlab.toolbox.image.tag" => ci_commit_sha,
      "gitlab.sidekiq.annotations.commit" => ci_short_sha,
      "gitlab.sidekiq.image.repository" => "#{image_repository}/gitlab-sidekiq-ee",
      "gitlab.sidekiq.image.tag" => ci_commit_sha,
      "gitlab.webservice.annotations.commit" => ci_short_sha,
      "gitlab.webservice.image.repository" => "#{image_repository}/gitlab-webservice-ee",
      "gitlab.webservice.image.tag" => ci_commit_sha,
      "gitlab.webservice.workhorse.image" => "#{image_repository}/gitlab-workhorse-ee",
      "gitlab.webservice.workhorse.tag" => ci_commit_sha,
      "gitlab.kas.image.repository" => "#{image_repository}/gitlab-kas",
      "gitlab.kas.image.tag" => kas_version,
      "gitlab.registry.image.repository" => "#{image_repository}/gitlab-container-registry",
      "gitlab.registry.image.tag" => ci_commit_sha
    })
  end

  context "with semver versions" do
    let(:gitaly_version) { "17.0.1" }
    let(:kas_version) { "17.0.1" }

    it "correctly sets image tags for components with semver version" do
      expect(described_class.component_ci_versions["gitlab.gitaly.image.tag"]).to eq("v#{gitaly_version}")
      expect(described_class.component_ci_versions["gitlab.kas.image.tag"]).to eq("v#{kas_version}")
    end
  end

  context "with explicitly provided image tags" do
    let(:image_tags) do
      {
        "GITALY_TAG" => "13b6c124a0fe566c7e3db4477600e0f004ab69bc",
        "GITLAB_SHELL_TAG" => "e6daa09dbb6ded5529224acdd1fd24000866aaaf",
        "GITLAB_TOOLBOX_TAG" => "e6ce8d7f67c0787c706d5968a1f84c5e2d4f2368",
        "GITLAB_SIDEKIQ_TAG" => "1088d209ac5dd8d245b00946de0760eb8fc9a181",
        "GITLAB_WEBSERVICE_TAG" => "b0ccc088a766801c8db9e7c564ad28472f33916c",
        "GITLAB_WORKHORSE_TAG" => "4a3990fb621ba6f6b7ddf36089868b24e22bb598",
        "GITLAB_KAS_TAG" => "03faf0a4227405febb714c4eaa78e4f16f5d0a37",
        "GITLAB_CONTAINER_REGISTRY_TAG" => "595f6534d8286bf1b9d3b1f527cb3af93a9a63c5"
      }
    end

    it "uses explicitly provided image tags" do
      expect(described_class.component_ci_versions).to include({
        "gitlab.gitaly.image.tag" => image_tags["GITALY_TAG"],
        "gitlab.gitlab-shell.image.tag" => image_tags["GITLAB_SHELL_TAG"],
        "gitlab.toolbox.image.tag" => image_tags["GITLAB_TOOLBOX_TAG"],
        "gitlab.sidekiq.image.tag" => image_tags["GITLAB_SIDEKIQ_TAG"],
        "gitlab.webservice.image.tag" => image_tags["GITLAB_WEBSERVICE_TAG"],
        "gitlab.webservice.workhorse.tag" => image_tags["GITLAB_WORKHORSE_TAG"],
        "gitlab.kas.image.tag" => image_tags["GITLAB_KAS_TAG"],
        "gitlab.registry.image.tag" => image_tags["GITLAB_CONTAINER_REGISTRY_TAG"]
      })
    end
  end
end
