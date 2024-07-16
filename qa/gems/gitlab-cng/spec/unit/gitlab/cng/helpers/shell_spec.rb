# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Helpers::Shell do
  subject(:helper) do
    Class.new do
      include Gitlab::Cng::Helpers::Shell
    end.new
  end

  let(:wait_thr) { instance_double(Process::Waiter, value: instance_double(Process::Status, success?: success)) }
  let(:stdin) { StringIO.new }
  let(:stdout) { StringIO.new("cmd-output") }
  let(:success) { true }

  before do
    allow(Open3).to receive(:popen2e).and_yield(stdin, stdout, wait_thr)
  end

  context "with wrong cmd arg" do
    it "raises error if cmd is not array" do
      expect { helper.execute_shell("cmd") }.to raise_error("System commands must be given as an array of strings")
    end

    it "raises error if cmd is not space separated array list" do
      expect { helper.execute_shell(["cmd with a space"]) }.to raise_error(
        "System commands must be split into an array of space-separated values"
      )
    end
  end

  context "with a successful command" do
    it "returns the output of the command" do
      cmd = "cmd"
      env = { custom_env: "custom_value" }

      expect(helper.execute_shell([cmd], env: env)).to eq("cmd-output")
      expect(Open3).to have_received(:popen2e).with(env, cmd)
    end

    it "returns output and status with raise_on_failure: false" do
      expect(helper.execute_shell(["cmd"], raise_on_failure: false)).to eq(["cmd-output", wait_thr.value])
    end

    it "writes stdin data" do
      expect(helper.execute_shell(["cmd"], stdin_data: "stdin")).to eq("cmd-output")
      expect(stdin.string).to eq("stdin")
    end
  end

  context "with a failed command" do
    let(:success) { false }

    it "raises command failed error" do
      expect { helper.execute_shell(["cmd"]) }.to raise_error(
        Gitlab::Cng::Helpers::Shell::CommandFailure,
        "Command 'cmd' failed!\ncmd-output"
      )
    end

    it "returns output and status with raise_on_failure: false" do
      expect(helper.execute_shell(["cmd"], raise_on_failure: false)).to eq(["cmd-output", wait_thr.value])
    end
  end
end
