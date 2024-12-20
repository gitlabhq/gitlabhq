# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::RunnableSpecs do
  let(:runnable_specs) { described_class.fetch(tests) }

  let(:tests) { nil }
  let(:examples) { [] }

  before do
    allow(ENV).to receive(:delete)
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(Logger.new(StringIO.new))
    allow(QA::Support::ExampleData).to receive(:fetch).and_return(examples)
  end

  context "with rspec returning runnable specs" do
    let(:examples) do
      [
        {
          file_path: "./qa/specs/features/ee/test_spec.rb"
        }
      ]
    end

    it "returns runnable spec list" do
      expect(runnable_specs).not_to be_empty
      expect(runnable_specs.values.all?(["qa/specs/features/ee/test_spec.rb"])).to(
        be(true), "Expected all scenarios to have runnable specs"
      )
      expect(runnable_specs.keys.all?(Class)).to(
        be(true), "Expected all scenarios to be classes"
      )
      expect(QA::Support::ExampleData).to have_received(:fetch).with(
        kind_of(Array),
        nil,
        logger: kind_of(Logger)
      ).at_least(:twice)
    end

    it "removes ignored scenario" do
      expect(runnable_specs.keys).not_to include(QA::Scenario::Test::Sanity::Selectors)
    end
  end

  context "with rspec returning no runnable specs" do
    it "returns empty spec list" do
      expect(runnable_specs).to be_empty
    end
  end

  context "with specific spec list" do
    let(:tests) { %w[spec_1.rb spec_2.rb] }

    it "fetches example data using specific spec list" do
      runnable_specs

      expect(QA::Support::ExampleData).to have_received(:fetch).with(
        kind_of(Array),
        tests,
        logger: kind_of(Logger)
      ).at_least(:twice)
    end
  end
end
