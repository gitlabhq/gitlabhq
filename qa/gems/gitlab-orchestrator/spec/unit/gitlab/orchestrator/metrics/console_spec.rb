# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Metrics::Console do
  shared_examples "graph output" do
    it "generates cpu graphs" do
      console.generate(type)

      expect(output.string).to eq(graph)
    end
  end

  subject(:console) { described_class.new(metrics_file, max_width: 100) }

  let(:time) { Time.parse("2025-05-27 00:00:00") }
  let(:output) { StringIO.new }

  let(:fixture_path) { "spec/fixtures/metrics" }
  let(:metrics_file) { File.join(fixture_path, "metrics#{fixture_file_postfix}.json") }
  let(:graph_file) { File.join(fixture_path, "metrics-#{type}#{fixture_file_postfix}.txt") }
  let(:fixture_file_postfix) { resource_definition.blank? ? nil : "-#{resource_definition}" }
  let(:graph) { File.read(graph_file) }
  let(:resource_definition) { nil }

  before do
    allow(Gitlab::Orchestrator::Helpers::Output).to receive(:rainbow).and_return(Rainbow::Wrapper.new(false))
    allow(Time).to receive(:now).and_return(time)
  end

  # rubocop:disable RSpec/ExpectOutput -- makes creating expected graph result output much easier
  around do |example|
    original_stdout = $stdout
    $stdout = output

    example.run

    $stdout = original_stdout
  end
  # rubocop:enable RSpec/ExpectOutput

  after do |example|
    # graph console output is hard to capture properly for string comparison,
    # simplify updating expectation by automatically saving new output in case of a failure
    File.write(graph_file, output.string) if example.exception
  end

  context "with limits and resources" do
    context "with cpu graph" do
      let(:type) { "cpu" }

      it_behaves_like "graph output"
    end

    context "with memory graph" do
      let(:type) { "memory" }

      it_behaves_like "graph output"
    end
  end

  context "without limits" do
    let(:resource_definition) { "no-limits" }

    context "with cpu graph" do
      let(:type) { "cpu" }

      it_behaves_like "graph output"
    end

    context "with memory graph" do
      let(:type) { "memory" }

      it_behaves_like "graph output"
    end
  end

  context "without requests" do
    let(:resource_definition) { "no-requests" }

    context "with cpu graph" do
      let(:type) { "cpu" }

      it_behaves_like "graph output"
    end

    context "with memory graph" do
      let(:type) { "memory" }

      it_behaves_like "graph output"
    end
  end
end
