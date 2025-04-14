# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Instance::Installation, :aggregate_failures do
  subject(:installation) do
    described_class.new(
      "gitlab-container",
      configuration: configuration,
      ci: ci,
      gitlab_domain: gitlab_domain,
      timeout: "10m",
      env: ["RAILS_ENV_VAR=val"],
      retry: retry_attempts
    )
  end

  let(:config_values) do
    {
      image: "gitlab/gitlab-ee:latest",
      environment: {
        GITLAB_OMNIBUS_CONFIG: "config",
        GITLAB_ROOT_PASSWORD: "password123"
      },
      ports: {
        "8080:80" => nil
      },
      restart: "always"
    }
  end

  let(:gitlab_domain) { "gitlab.example.com" }
  let(:ci) { false }
  let(:retry_attempts) { 0 }

  let(:docker_client) do
    instance_double(
      Gitlab::Orchestrator::Docker::Client,
      pull_image: nil,
      run_container: nil
    )
  end

  let(:configuration) do
    instance_double(
      Gitlab::Orchestrator::Instance::Configurations::Gitlab,
      run_pre_installation_setup: nil,
      run_post_installation_setup: nil,
      values: config_values,
      gitlab_url: "http://#{gitlab_domain}:8080"
    )
  end

  before do
    allow(Gitlab::Orchestrator::Helpers::Spinner).to receive(:spin).and_yield
    allow(Gitlab::Orchestrator::Docker::Client).to receive(:new).and_return(docker_client)
    allow(installation).to receive(:log)
  end

  describe "#create" do
    context "with successful installation" do
      it "runs setup and docker container creation" do
        allow(installation).to receive(:log) do |message, level, **opts|
          puts message if level == :info && opts[:bright]
        end

        config_values[:volumes] = {}

        expect { installation.create }.to output(/Creating docker container instance 'gitlab-container'/).to_stdout

        expect(docker_client).to have_received(:pull_image).with("gitlab/gitlab-ee:latest")
        expect(docker_client).to have_received(:run_container).with(
          name: "gitlab-container",
          image: "gitlab/gitlab-ee:latest",
          environment: {
            GITLAB_OMNIBUS_CONFIG: "config",
            GITLAB_ROOT_PASSWORD: "password123",
            "RAILS_ENV_VAR" => "val"
          },
          ports: { "8080:80" => nil },
          volumes: {},
          restart: "always",
          additional_options: ["--shm-size", "256m"]
        )

        expect(configuration).to have_received(:run_pre_installation_setup)
        expect(configuration).to have_received(:run_post_installation_setup)
      end
    end

    context "with installation failure" do
      before do
        allow(docker_client).to receive(:run_container)
          .and_raise(Gitlab::Orchestrator::Docker::Error, "Failed to run container")

        allow(installation).to receive(:handle_install_failure) do |error|
          puts "Docker container creation failed!"
          puts "For more information on troubleshooting failures, see: '#{described_class::TROUBLESHOOTING_LINK}'"
          raise error
        end
      end

      context "without retry" do
        it "exits with error and troubleshooting info" do
          expect { expect { installation.create }.to raise_error(SystemExit) }.to output(
            match(/Docker container creation failed!/)
            .and(match(/For more information on troubleshooting failures, see: \S+/))
          ).to_stdout
        end
      end

      context "with retry" do
        let(:retry_attempts) { 1 }

        it "retries installation before failing" do
          allow(installation).to receive(:log) do |message, level, **_opts|
            puts message if level == :warn
          end

          installation_attempts = 0

          original_run_install = installation.method(:run_install)
          allow(installation).to receive(:run_install) do
            installation_attempts += 1

            original_run_install.call
          end

          expect { expect { installation.create }.to raise_error(SystemExit) }.to output(
            match(/Installation failed, retrying.../)
            .and(match(/Docker container creation failed!/))
          ).to_stdout

          expect(docker_client).to have_received(:pull_image).twice
        end
      end
    end

    context "with installation failure and retry" do
      let(:retry_attempts) { 2 }

      it "retries the specified number of times before failing" do
        call_count = 0

        allow(docker_client).to receive(:pull_image) do
          call_count += 1
        end

        allow(docker_client).to receive(:run_container) do
          raise Gitlab::Orchestrator::Docker::Error, "Failed to run container" if call_count <= 2
        end

        installation.instance_variable_set(:@installation_attempts, 0)

        allow(installation).to receive(:log)

        installation.send(:run_install)

        expect(docker_client).to have_received(:pull_image).exactly(3).times
        expect(docker_client).to have_received(:run_container).exactly(3).times
        expect(installation).to have_received(:log).with("Installation failed, retrying...", :warn).twice
      end
    end
  end

  describe "#env_values" do
    it "parses environment variables correctly" do
      expect(installation.send(:env_values)).to eq({ "RAILS_ENV_VAR" => "val" })
    end

    it "handles empty environment variables" do
      installation = described_class.new(
        "gitlab-container",
        configuration: configuration,
        ci: ci,
        gitlab_domain: gitlab_domain,
        timeout: "10m"
      )

      expect(installation.send(:env_values)).to eq({})
    end

    it "handles invalid environment variables" do
      installation = described_class.new(
        "gitlab-container",
        configuration: configuration,
        ci: ci,
        gitlab_domain: gitlab_domain,
        timeout: "10m",
        env: ["INVALID_FORMAT"]
      )

      expect(installation.send(:env_values)).to eq({})
    end
  end

  describe "#docker_client" do
    it "returns a docker client instance" do
      expect(installation.send(:docker_client)).to eq(docker_client)
      expect(Gitlab::Orchestrator::Docker::Client).to have_received(:new).once
    end

    it "memoizes the docker client" do
      client1 = installation.send(:docker_client)
      client2 = installation.send(:docker_client)

      expect(client1).to eq(client2)
      expect(Gitlab::Orchestrator::Docker::Client).to have_received(:new).once
    end
  end

  describe "#run_pre_install_setup" do
    it "calls configuration pre-installation setup" do
      installation.send(:run_pre_install_setup)

      expect(configuration).to have_received(:run_pre_installation_setup)
    end
  end

  describe "#run_post_install_setup" do
    it "calls configuration post-installation setup" do
      installation.send(:run_post_install_setup)

      expect(configuration).to have_received(:run_post_installation_setup)
    end
  end

  describe "#run_install" do
    before do
      config_values[:volumes] = {}
    end

    it "pulls the image and runs the container" do
      installation.send(:run_install)

      expect(docker_client).to have_received(:pull_image).with("gitlab/gitlab-ee:latest")
      expect(docker_client).to have_received(:run_container).with(
        name: "gitlab-container",
        image: "gitlab/gitlab-ee:latest",
        environment: {
          GITLAB_OMNIBUS_CONFIG: "config",
          GITLAB_ROOT_PASSWORD: "password123",
          "RAILS_ENV_VAR" => "val"
        },
        ports: { "8080:80" => nil },
        volumes: {},
        restart: "always",
        additional_options: ["--shm-size", "256m"]
      )
    end

    context "with installation failure and retry" do
      let(:retry_attempts) { 2 }

      it "retries the specified number of times before failing" do
        call_count = 0

        allow(docker_client).to receive(:pull_image) do
          call_count += 1
        end

        allow(docker_client).to receive(:run_container) do
          raise Gitlab::Orchestrator::Docker::Error, "Failed to run container" if call_count <= 2
        end

        installation.instance_variable_set(:@installation_attempts, 0)

        allow(installation).to receive(:log)

        installation.send(:run_install)

        expect(docker_client).to have_received(:pull_image).exactly(3).times
        expect(docker_client).to have_received(:run_container).exactly(3).times
        expect(installation).to have_received(:log).with("Installation failed, retrying...", :warn).twice
      end
    end
  end

  describe "#handle_install_failure" do
    it "logs error and raises the original error" do
      error = Gitlab::Orchestrator::Docker::Error.new("Test error")

      expect { installation.send(:handle_install_failure, error) }.to raise_error(error)

      expect(installation).to have_received(:log).with("Docker container creation failed!", :error)
      expect(installation).to have_received(:log).with(
        "For more information on troubleshooting failures, see: 'https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/gems/gitlab-orchestrator?ref_type=heads#troubleshooting'",
        :warn
      )
    end
  end
end
