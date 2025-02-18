# frozen_string_literal: true

RSpec.describe QA::Support::ExampleData do
  let(:example_data) { described_class.fetch(tags, spec_files) }

  let(:run_result_file) { instance_double(File, path: "file_path") }
  let(:process_output_file) { instance_double(File, path: "output.log") }
  let(:rspec_json) { { examples: [file_path: "spec.rb"] } }
  let(:rspec_exit) { 0 }

  let(:tags) { [] }
  let(:spec_files) { [] }
  let(:default_tags) { QA::Specs::Runner::DEFAULT_SKIPPED_TAGS }
  let(:default_spec_files) { QA::Specs::Runner::DEFAULT_TEST_PATH_ARGS - ["--"] }

  before do
    allow(ENV).to receive(:store)
    allow(QA::Runtime::Logger).to receive_messages({ debug: nil, error: nil })

    allow(Tempfile).to receive(:open).with("test-metadata.json").and_yield(run_result_file)
    allow(Tempfile).to receive(:open).with("output.log").and_yield(process_output_file)
    allow(File).to receive(:read).with(process_output_file.path).and_return("output")
    allow(JSON).to receive(:load_file).with(run_result_file, symbolize_names: true).and_return(rspec_json)

    allow(RSpec::Core::Runner).to receive(:run).and_return(rspec_exit)

    allow(Process).to receive(:fork).and_yield
    allow(Process).to receive(:wait2).and_return(
      [1, instance_double(Process::Status, success?: rspec_exit.nonzero? ? false : true)]
    )
    allow(Kernel).to receive(:exit)
  end

  def rspec_args(tags = default_tags, spec_files = default_spec_files)
    [
      "--out", process_output_file.path,
      "--dry-run",
      "--no-color",
      "--format", QA::Support::JsonFormatter.to_s, "--out", run_result_file.path,
      *tags.flat_map { |tag| ["--tag", tag] },
      "--",
      *spec_files
    ]
  end

  it "calls rspec run with default arguments" do
    expect(example_data).to eq(rspec_json[:examples])
    expect(RSpec::Core::Runner).to have_received(:run).with(rspec_args)
  end

  it "sets dry run variable" do
    example_data

    expect(ENV).to have_received(:store).with("QA_RSPEC_DRY_RUN", "true")
  end

  context "with specific tags and specs" do
    let(:tags) { %w[foo bar] }
    let(:spec_files) { %w[path/to/spec1.rb path/to/spec2.rb] }

    it "calls rspec run with correct arguments" do
      expect(example_data).to eq(rspec_json[:examples])
      expect(RSpec::Core::Runner).to have_received(:run).with(rspec_args(tags, spec_files))
    end
  end

  context "with rspec process failure" do
    let(:rspec_exit) { 1 }

    before do
      # skip yielding fork block to correctly raise error
      allow(Process).to receive(:fork)
    end

    it "raises error" do
      expect { example_data }.to raise_error(
        RuntimeError, "Failed to fetch example data for tags '#{default_tags}' and specs '#{spec_files}'"
      )
    end
  end
end
