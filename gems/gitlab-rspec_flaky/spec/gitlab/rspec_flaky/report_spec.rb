# frozen_string_literal: true

require 'tempfile'

require 'gitlab/rspec_flaky/report'

RSpec.describe Gitlab::RspecFlaky::Report, :aggregate_failures, :freeze_time do
  let(:thirty_one_days) { 3600 * 24 * 31 }
  let(:collection_hash) do
    {
      a: { example_id: 'spec/foo/bar_spec.rb:2' },
      b: { example_id: 'spec/foo/baz_spec.rb:3', first_flaky_at: (Time.now - thirty_one_days).to_s,
           last_flaky_at: (Time.now - thirty_one_days).to_s }
    }
  end

  let(:suite_flaky_example_report) do
    {
      '6e869794f4cfd2badd93eb68719371d1': {
        example_id: 'spec/foo/bar_spec.rb:2',
        file: 'spec/foo/bar_spec.rb',
        line: 2,
        description: 'hello world',
        first_flaky_at: 1234,
        last_flaky_at: 4321,
        last_attempts_count: 3,
        flaky_reports: 1,
        feature_category: 'feature_category',
        last_flaky_job: nil
      }
    }
  end

  let(:flaky_examples) { Gitlab::RspecFlaky::FlakyExamplesCollection.new(collection_hash) }
  let(:report) { described_class.new(flaky_examples) }

  before do
    allow(Kernel).to receive(:warn)
  end

  describe '.load' do
    let!(:report_file) do
      Tempfile.new(%w[rspec_flaky_report .json]).tap do |f|
        f.write(JSON.pretty_generate(suite_flaky_example_report))
        f.rewind
      end
    end

    after do
      report_file.close
      report_file.unlink
    end

    it 'loads the report file' do
      expect(described_class.load(report_file.path).flaky_examples.to_h).to eq(suite_flaky_example_report)
    end
  end

  describe '.load_json' do
    let(:report_json) do
      JSON.pretty_generate(suite_flaky_example_report)
    end

    it 'loads the report file' do
      expect(described_class.load_json(report_json).flaky_examples.to_h).to eq(suite_flaky_example_report)
    end
  end

  describe '#initialize' do
    it 'accepts a Gitlab::RspecFlaky::FlakyExamplesCollection' do
      expect { report }.not_to raise_error
    end

    it 'does not accept anything else' do
      expect do
        described_class.new([1, 2,
          3])
      end.to raise_error(ArgumentError,
        "`flaky_examples` must be a Gitlab::RspecFlaky::FlakyExamplesCollection, Array given!")
    end
  end

  it 'delegates to #flaky_examples using SimpleDelegator' do
    expect(report.__getobj__).to eq(flaky_examples)
  end

  describe '#write' do
    let(:report_file_path) { File.join('tmp', 'rspec_flaky_report.json') }

    before do
      FileUtils.rm_f(report_file_path)
    end

    after do
      FileUtils.rm_f(report_file_path)
    end

    context 'when Gitlab::RspecFlaky::Config.generate_report? is false' do
      before do
        allow(Gitlab::RspecFlaky::Config).to receive(:generate_report?).and_return(false)
      end

      it 'does not write any report file' do
        report.write(report_file_path)

        expect(File.exist?(report_file_path)).to be(false)
      end
    end

    context 'when Gitlab::RspecFlaky::Config.generate_report? is true' do
      before do
        allow(Gitlab::RspecFlaky::Config).to receive(:generate_report?).and_return(true)
      end

      it 'delegates the writes to Gitlab::RspecFlaky::Report' do
        report.write(report_file_path)

        expect(File.exist?(report_file_path)).to be(true)
        expect(File.read(report_file_path))
          .to eq(JSON.pretty_generate(report.flaky_examples.to_h))
      end
    end
  end

  describe '#prune_outdated' do
    it 'returns a new collection without the examples older than 30 days by default' do
      new_report = flaky_examples.to_h.dup.tap { |r| r.delete(:b) }
      new_flaky_examples = report.prune_outdated

      expect(new_flaky_examples).to be_a(described_class)
      expect(new_flaky_examples.to_h).to eq(new_report)
      expect(flaky_examples).to have_key(:b)
    end

    it 'accepts a given number of days' do
      new_flaky_examples = report.prune_outdated(days: 32)

      expect(new_flaky_examples.to_h).to eq(report.to_h)
    end
  end
end
