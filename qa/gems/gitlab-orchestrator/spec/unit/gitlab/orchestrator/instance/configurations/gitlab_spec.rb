# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Instance::Configurations::Gitlab do
  subject(:configuration) do
    described_class.new(
      image: "gitlab/gitlab-ee:latest",
      ci: true,
      gitlab_domain: "gitlab.example.com",
      admin_password: "password123",
      host_http_port: 8080
    )
  end

  let(:docker_client) do
    instance_double(Gitlab::Orchestrator::Docker::Client)
  end

  before do
    allow(Gitlab::Orchestrator::Docker::Client).to receive(:new).and_return(docker_client)
  end

  describe "#run_pre_installation_setup" do
    it "does not perform any pre-installation setup" do
      expect { configuration.run_pre_installation_setup }.not_to raise_error
    end
  end

  describe "#run_post_installation_setup" do
    it "waits for GitLab to be ready" do
      allow(configuration).to receive(:wait_for_gitlab_ready)

      configuration.run_post_installation_setup

      expect(configuration).to have_received(:wait_for_gitlab_ready)
    end
  end

  describe "#values" do
    it "returns configuration specific values" do
      expected_omnibus_config = <<~RUBY
        external_url 'http://gitlab.example.com';
        gitlab_rails['gitlab_default_theme'] = 10;
        gitlab_rails['gitlab_disable_animations'] = true;
        gitlab_rails['application_settings_cache_seconds'] = 0;
        gitlab_rails['env']['GITLAB_LICENSE_MODE'] = 'test';
        gitlab_rails['env']['CUSTOMER_PORTAL_URL'] = 'https://customers.staging.gitlab.com';
        gitlab_rails['env']['GITLAB_ALLOW_SEPARATE_CI_DATABASE'] = 'false';
        gitlab_rails['env']['COVERBAND_ENABLED'] = 'false';
      RUBY

      expect(configuration.values).to eq({
        image: "gitlab/gitlab-ee:latest",
        environment: {
          GITLAB_OMNIBUS_CONFIG: expected_omnibus_config,
          GITLAB_ROOT_PASSWORD: "password123"
        },
        ports: {
          "8080:80" => nil
        },
        restart: "always"
      })
    end
  end

  describe "#gitlab_url" do
    it "returns correct gitlab url" do
      expect(configuration.gitlab_url).to eq("http://gitlab.example.com:8080")
    end
  end

  describe "#wait_for_gitlab_ready" do
    let(:success_response) { instance_double(Net::HTTPResponse, code: "200") }
    let(:failure_response) { instance_double(Net::HTTPResponse, code: "502") }

    before do
      allow(configuration).to receive(:wait_for_gitlab_ready).and_call_original
      allow(configuration).to receive(:log)
      allow(Gitlab::Orchestrator::Helpers::Spinner).to receive(:spin).and_yield
    end

    it "waits until GitLab is ready" do
      expect(Net::HTTP).to receive(:get_response).with(URI("http://gitlab.example.com:8080/users/sign_in"))
        .and_return(failure_response, success_response)

      allow(configuration).to receive(:sleep)

      configuration.send(:wait_for_gitlab_ready)

      expect(configuration).to have_received(:log).with("GitLab is ready! 🚀", :success)
      expect(configuration).to have_received(:sleep).once
    end

    it "raises error when GitLab does not become ready in time" do
      allow(Net::HTTP).to receive(:get_response).with(URI("http://gitlab.example.com:8080/users/sign_in"))
        .and_return(failure_response)

      allow(configuration).to receive(:sleep)

      expect { configuration.send(:wait_for_gitlab_ready) }.to raise_error("Timed out waiting for GitLab to be ready")
      expect(configuration).to have_received(:sleep).exactly(30).times
    end

    it "handles connection errors during readiness check" do
      call_count = 0
      allow(Net::HTTP).to receive(:get_response) do |_uri|
        call_count += 1
        raise StandardError, "Connection refused" if call_count == 1

        success_response
      end

      allow(configuration).to receive(:sleep)

      configuration.send(:wait_for_gitlab_ready)

      expect(configuration).to have_received(:log).with("GitLab is not ready yet. Reason: Connection refused",
        :debug).ordered
      expect(configuration).to have_received(:log).with("GitLab is ready! 🚀", :success).ordered
      expect(configuration).to have_received(:sleep).once
    end
  end

  describe "#docker_client" do
    it "returns a docker client instance" do
      expect(configuration.send(:docker_client)).to eq(docker_client)
      expect(Gitlab::Orchestrator::Docker::Client).to have_received(:new).once
    end

    it "memoizes the docker client" do
      client1 = configuration.send(:docker_client)
      client2 = configuration.send(:docker_client)

      expect(client1).to eq(client2)
      expect(Gitlab::Orchestrator::Docker::Client).to have_received(:new).once
    end
  end

  describe "#omnibus_config" do
    it "returns the default omnibus configuration" do
      expected_config = <<~RUBY
        external_url 'http://gitlab.example.com';
        gitlab_rails['gitlab_default_theme'] = 10;
        gitlab_rails['gitlab_disable_animations'] = true;
        gitlab_rails['application_settings_cache_seconds'] = 0;
        gitlab_rails['env']['GITLAB_LICENSE_MODE'] = 'test';
        gitlab_rails['env']['CUSTOMER_PORTAL_URL'] = 'https://customers.staging.gitlab.com';
        gitlab_rails['env']['GITLAB_ALLOW_SEPARATE_CI_DATABASE'] = 'false';
        gitlab_rails['env']['COVERBAND_ENABLED'] = 'false';
      RUBY

      expect(configuration.send(:omnibus_config)).to eq(expected_config)
    end
  end
end
