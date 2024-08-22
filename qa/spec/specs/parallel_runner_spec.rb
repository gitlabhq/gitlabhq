# frozen_string_literal: true

require 'etc'

RSpec.describe QA::Specs::ParallelRunner do
  include QA::Support::Helpers::StubEnv

  subject(:runner) { described_class }

  let(:parallel_tests) { instance_double(ParallelTests::CLI, run: nil) }

  before do
    allow(ParallelTests::CLI).to receive(:new).and_return(parallel_tests)
    allow(Etc).to receive(:nprocessors).and_return(8)
    allow(ENV).to receive(:store)

    allow(QA::Runtime::Browser).to receive(:configure!)
    allow(QA::Runtime::Release).to receive(:perform_before_hooks)

    stub_env("QA_GITLAB_URL", "http://127.0.0.1:3000")
    stub_env("QA_PARALLEL_PROCESSES", "8")
  end

  it "runs cli without additional rspec args" do
    runner.run([])

    expect(parallel_tests).to have_received(:run).with([
      "--type", "rspec",
      "-n", "8",
      "--serialize-stdout",
      "--first-is-1",
      "--combine-stderr"
    ])
  end

  it "runs cli with additional rspec args" do
    runner.run(["--force-color", "qa/specs/features/api"])

    expect(parallel_tests).to have_received(:run).with([
      "--type", "rspec",
      "-n", "8",
      "--serialize-stdout",
      "--first-is-1",
      "--combine-stderr",
      "--", "--force-color",
      "--", "qa/specs/features/api"
    ])
  end

  context "with QA_GITLAB_URL not set" do
    before do
      stub_env("QA_GITLAB_URL", nil)

      QA::Support::GitlabAddress.instance_variable_set(:@initialized, nil)
    end

    after do
      QA::Support::GitlabAddress.instance_variable_set(:@initialized, nil)
    end

    it "sets QA_GITLAB_URL variable for subprocess" do
      runner.run([])

      expect(ENV).to have_received(:store).with("QA_GITLAB_URL", "http://127.0.0.1:3000")
    end
  end
end
