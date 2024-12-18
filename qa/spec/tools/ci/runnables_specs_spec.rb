# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::RunnableSpecs do
  let(:runnable_specs) { described_class.new([]).fetch }

  let(:config_mock) { instance_double(RSpec::Core::Configuration, add_formatter: nil) }
  let(:run_result_file) { instance_double(File, path: "file_path") }
  let(:rspec_json) { { examples: [] } }
  let(:rspec_exit) { 0 }

  before do
    allow(ENV).to receive(:delete)
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(Logger.new(StringIO.new))
    allow(Tempfile).to receive(:open).with("test-metadata.json").and_yield(run_result_file)
    allow(JSON).to receive(:load_file).with(run_result_file, symbolize_names: true).and_return(rspec_json)
    allow(RSpec).to receive(:configure).and_yield(config_mock)
    allow(RSpec::Core::Runner).to receive(:run).and_return(rspec_exit)
    allow(Process).to receive(:fork).and_yield
    allow(Process).to receive(:wait2).and_return(
      [1, instance_double(Process::Status, success?: rspec_exit.nonzero? ? false : true)]
    )
    allow(Kernel).to receive(:exit)
  end

  it "correctly configures formatter" do
    runnable_specs

    expect(config_mock).to have_received(:add_formatter)
      .with(QA::Support::JsonFormatter, run_result_file.path)
      .at_least(:once)
  end

  context "with rspec process failure" do
    let(:rspec_exit) { 1 }

    before do
      # skip yielding fork block to correctly raise error
      allow(Process).to receive(:fork)
    end

    it "raises error" do
      expect { runnable_specs }.to raise_error(RuntimeError, /Failed to fetch executable spec files for .*/)
    end
  end

  context "with rspec returning runnable specs" do
    let(:rspec_json) do
      {
        examples: [
          {
            file_path: "./qa/specs/features/ee/test_spec.rb"
          }
        ]
      }
    end

    it "returns runnable spec list" do
      expect(runnable_specs.all? { |_k, v| v == ["qa/specs/features/ee/test_spec.rb"] }).to be true
    end
  end

  context "with rspec returning no runnable specs" do
    it "returns empty spec list" do
      expect(runnable_specs.all? { |_k, v| v == [] }).to be true
    end
  end
end
