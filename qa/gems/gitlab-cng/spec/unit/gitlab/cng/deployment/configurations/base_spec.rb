# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::Configurations::Base do
  subject(:configuration) { Class.new(described_class) }

  let(:config) do
    configuration.new(
      namespace: "gitlab",
      ci: false,
      gitlab_domain: "domain"
    )
  end

  it "returns empty values by default" do
    expect(config.values).to eq({})
  end

  it "returns correct default gitlab_url" do
    expect(config.gitlab_url).to eq("http://gitlab.domain")
  end

  it "has setup hooks enabled by default", :aggregate_failures do
    expect { config.run_pre_deployment_setup }.to raise_error(
      NoMethodError,
      "run_pre_deployment_setup not implemented"
    )
    expect { config.run_post_deployment_setup }.to raise_error(
      NoMethodError,
      "run_post_deployment_setup not implemented"
    )
  end

  context "with disabled setup hooks" do
    subject(:configuration) do
      Class.new(described_class) do
        skip_pre_deployment_setup!
        skip_post_deployment_setup!
      end
    end

    it "does not run setup hooks" do
      expect(config.run_pre_deployment_setup).to be_nil
      expect(config.run_post_deployment_setup).to be_nil
    end
  end
end
