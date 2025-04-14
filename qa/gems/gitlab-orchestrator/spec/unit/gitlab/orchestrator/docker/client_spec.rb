# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Docker::Client do
  subject(:client) { described_class.new }

  before do
    allow(client).to receive(:execute_shell).and_return("")
  end

  describe "#container_exists?" do
    it "returns true when container exists" do
      allow(client).to receive(:execute_shell)
        .with(["docker", "ps", "-a", "-q", "-f", "name=^/test-container$"])
        .and_return("container-id")

      expect(client.container_exists?("test-container")).to be(true)
    end

    it "returns false when container does not exist" do
      allow(client).to receive(:execute_shell)
        .with(["docker", "ps", "-a", "-q", "-f", "name=^/test-container$"])
        .and_return("")

      expect(client.container_exists?("test-container")).to be(false)
    end

    it "raises error when command fails" do
      allow(client).to receive(:execute_shell)
        .with(["docker", "ps", "-a", "-q", "-f", "name=^/test-container$"])
        .and_raise(StandardError.new("something went wrong"))

      expect { client.container_exists?("test-container") }
        .to raise_error(Gitlab::Orchestrator::Docker::Error,
          "Failed to check if container exists: something went wrong")
    end
  end

  describe "#create_volume" do
    it "creates a docker volume" do
      expect(client.create_volume("test-volume")).to eq("")
      expect(client).to have_received(:execute_shell).with(%w[docker volume create test-volume])
    end

    it "raises error when command fails" do
      allow(client).to receive(:execute_shell)
        .with(%w[docker volume create test-volume])
        .and_raise(StandardError.new("something went wrong"))

      expect { client.create_volume("test-volume") }
        .to raise_error(Gitlab::Orchestrator::Docker::Error, "Failed to create volume: something went wrong")
    end
  end

  describe "#pull_image" do
    it "pulls a docker image" do
      expect(client.pull_image("test-image:latest")).to eq("")
      expect(client).to have_received(:execute_shell).with(
        ["docker", "pull", "test-image:latest"],
        live_output: true
      )
    end

    it "raises error when command fails" do
      allow(client).to receive(:execute_shell)
        .with(["docker", "pull", "test-image:latest"], live_output: true)
        .and_raise(StandardError.new("something went wrong"))

      expect { client.pull_image("test-image:latest") }
        .to raise_error(Gitlab::Orchestrator::Docker::Error, "Failed to pull Docker image: something went wrong")
    end
  end

  describe "#run_container" do
    before do
      allow(client).to receive(:log)
    end

    it "runs a container with minimal options" do
      expect(client.run_container(name: "test-container", image: "test-image:latest")).to eq("")

      expect(client).to have_received(:log).with(
        "Running container with command: docker run -d --name test-container --restart always test-image:latest",
        :debug
      )
      expect(client).to have_received(:execute_shell).with(
        ["docker", "run", "-d", "--name", "test-container", "--restart", "always", "test-image:latest"]
      )
    end

    it "runs a container with environment variables" do
      expect(client.run_container(
        name: "test-container",
        image: "test-image:latest",
        environment: { "VAR1" => "value1", "VAR2" => "value2" }
      )).to eq("")

      expect(client).to have_received(:execute_shell).with([
        "docker", "run", "-d", "--name", "test-container",
        "-e", "VAR1=value1", "-e", "VAR2=value2",
        "--restart", "always", "test-image:latest"
      ])
    end

    it "runs a container with port mappings" do
      expect(client.run_container(
        name: "test-container",
        image: "test-image:latest",
        ports: { "8080:80" => nil, "8443:443" => nil }
      )).to eq("")

      expect(client).to have_received(:execute_shell).with([
        "docker", "run", "-d", "--name", "test-container",
        "-p", "8080:80", "-p", "8443:443",
        "--restart", "always", "test-image:latest"
      ])
    end

    it "runs a container with volume mappings" do
      expect(client.run_container(
        name: "test-container",
        image: "test-image:latest",
        volumes: { "vol1:/data" => nil, "vol2:/config" => nil }
      )).to eq("")

      expect(client).to have_received(:execute_shell).with([
        "docker", "run", "-d", "--name", "test-container",
        "-v", "vol1:/data", "-v", "vol2:/config",
        "--restart", "always", "test-image:latest"
      ])
    end

    it "runs a container with additional options" do
      expect(client.run_container(
        name: "test-container",
        image: "test-image:latest",
        additional_options: ["--network=host", "--privileged"]
      )).to eq("")

      expect(client).to have_received(:execute_shell).with([
        "docker", "run", "-d", "--name", "test-container",
        "--restart", "always", "--network=host", "--privileged", "test-image:latest"
      ])
    end

    it "runs a container with custom restart policy" do
      expect(client.run_container(
        name: "test-container",
        image: "test-image:latest",
        restart: "no"
      )).to eq("")

      expect(client).to have_received(:execute_shell).with([
        "docker", "run", "-d", "--name", "test-container",
        "--restart", "no", "test-image:latest"
      ])
    end

    it "raises error when command fails" do
      allow(client).to receive(:execute_shell)
        .with(["docker", "run", "-d", "--name", "test-container", "--restart", "always", "test-image:latest"])
        .and_raise(StandardError.new("something went wrong"))

      expect { client.run_container(name: "test-container", image: "test-image:latest") }
        .to raise_error(Gitlab::Orchestrator::Docker::Error, "Failed to run container: something went wrong")
    end
  end

  describe "#exec" do
    it "executes a command in a container" do
      expect(client.exec("test-container", ["ls", "-la"])).to eq("")
      expect(client).to have_received(:execute_shell).with(["docker", "exec", "test-container", "ls", "-la"])
    end

    it "raises error when command fails" do
      allow(client).to receive(:execute_shell)
        .with(["docker", "exec", "test-container", "ls", "-la"])
        .and_raise(StandardError.new("something went wrong"))

      expect { client.exec("test-container", ["ls", "-la"]) }
        .to raise_error(Gitlab::Orchestrator::Docker::Error,
          "Failed to execute command in container: something went wrong")
    end
  end
end
