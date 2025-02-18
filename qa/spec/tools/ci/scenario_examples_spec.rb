# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::ScenarioExamples do
  subject(:example_fetcher) { described_class.new(tests) }

  let(:runnable_specs) { example_fetcher.fetch }

  let(:tests) { nil }
  let(:examples) { [] }

  before do
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(Logger.new(StringIO.new))
    allow(QA::Support::ExampleData).to receive(:fetch).and_return(examples)
  end

  context "with custom spec pattern in scenario class" do
    let(:specs) { ["specs/feature/fake_spec.rb"] }

    let(:scenario_class) do
      Class.new(QA::Scenario::Template) do
        spec_glob_pattern "specs/feature/*_spec.rb"
      end
    end

    before do
      allow(Dir).to receive(:glob).and_return(specs)
      allow(example_fetcher).to receive(:all_scenario_classes).and_return([scenario_class])
    end

    context "without specific specs" do
      it "uses pattern defined in scenario class" do
        example_fetcher.fetch

        expect(QA::Support::ExampleData).to have_received(:fetch).with([], specs, logger: kind_of(Logger))
      end
    end

    context "with specific tests" do
      let(:tests) { ["specs/feature/fake_spec.rb", "specs/ee/feature/fake_spec.rb"] }

      before do
        tests.each { |spec| allow(File).to receive(:file?).with(spec).and_return(true) }
      end

      it "uses only tests matching pattern in scenario class" do
        example_fetcher.fetch

        expect(QA::Support::ExampleData).to have_received(:fetch).with([], specs, logger: kind_of(Logger))
      end
    end

    context "with folder in specific test list" do
      let(:tests) { ["specs/feature", "specs/ee/feature"] }

      before do
        tests.each do |spec|
          allow(File).to receive(:file?).with(spec).and_return(false)
          allow(File).to receive(:directory?).with(spec).and_return(true)
        end
      end

      it "uses only tests matching pattern within folder" do
        example_fetcher.fetch

        expect(QA::Support::ExampleData).to have_received(:fetch).with([], specs, logger: kind_of(Logger))
      end
    end

    context "with specific tests not matching custom pattern" do
      let(:tests) { ["specs/ee/feature/fake_spec.rb"] }

      before do
        tests.each { |spec| allow(File).to receive(:file?).with(spec).and_return(true) }
      end

      it "returns empty list" do
        expect(runnable_specs).to eq(scenario_class => [])
        expect(QA::Support::ExampleData).not_to have_received(:fetch)
      end
    end
  end

  context "with rspec returning runnable specs" do
    let(:examples) do
      [
        {
          id: "./qa/specs/features/ee/test_spec.rb[1:1]",
          status: "passed"
        }
      ]
    end

    it "returns runnable spec list" do
      expect(runnable_specs.all? { |_k, v| v == examples }).to(
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
      expect(runnable_specs.values.all?(&:empty?)).to be(true)
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
