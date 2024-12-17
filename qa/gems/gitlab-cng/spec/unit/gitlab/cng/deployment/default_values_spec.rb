# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::DefaultValues do
  let(:ci_project_dir) { "/builds/dir" }
  let(:ci_commit_sha) { "0acb5ee6db0860436fafc2c31a2cd87849c51aa3" }
  let(:ci_short_sha) { "0acb5ee6db08" }
  let(:image_repository) { "registry.gitlab.com/gitlab-org/build/cng-mirror" }
  let(:gitaly_version) { "7aa06a578d76bdc294ee8e9acb4f063e7d9f1d5f" }
  let(:shell_version) { "14.0.5" }

  let(:env) do
    {
      "CI_PROJECT_DIR" => ci_project_dir,
      "CI_COMMIT_SHA" => ci_commit_sha,
      "CI_COMMIT_SHORT_SHA" => ci_short_sha
    }
  end

  before do
    described_class.instance_variable_set(:@ci_project_dir, nil)
    described_class.instance_variable_set(:@gitaly_version, nil)

    allow(File).to receive(:read).with(File.join(ci_project_dir, "GITALY_SERVER_VERSION")).and_return(gitaly_version)
    allow(File).to receive(:read).with(File.join(ci_project_dir, "GITLAB_SHELL_VERSION")).and_return(shell_version)
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
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
      "gitlab.webservice.workhorse.tag" => ci_commit_sha
    })
  end

  context "with semver gitaly version" do
    let(:gitaly_version) { "17.0.1" }

    it "correctly sets gitaly image tag" do
      expect(described_class.component_ci_versions["gitlab.gitaly.image.tag"]).to eq("v#{gitaly_version}")
    end
  end
end
