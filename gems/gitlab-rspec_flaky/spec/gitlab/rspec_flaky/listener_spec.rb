# frozen_string_literal: true

require 'gitlab/rspec_flaky/listener'

RSpec.describe Gitlab::RspecFlaky::Listener, :aggregate_failures do
  include StubENV

  let(:already_flaky_example_uid) { '6e869794f4cfd2badd93eb68719371d1' }
  let(:suite_flaky_example_report) do
    {
      "#{already_flaky_example_uid}": {
        example_id: 'spec/foo/bar_spec.rb:2',
        file: 'spec/foo/bar_spec.rb',
        line: 2,
        description: 'hello world',
        first_flaky_at: 1234,
        last_flaky_at: 4321,
        last_attempts_count: 3,
        flaky_reports: 1,
        last_flaky_job: nil
      }
    }
  end

  let(:already_flaky_example_attrs) do
    {
      id: 'spec/foo/bar_spec.rb:2',
      metadata: {
        file_path: 'spec/foo/bar_spec.rb',
        line_number: 2,
        full_description: 'hello world'
      },
      execution_result: double(status: 'passed', exception: nil)
    }
  end

  let(:already_flaky_example) do
    RspecFlaky::FlakyExample.new(suite_flaky_example_report[already_flaky_example_uid])
  end

  let(:new_example_attrs) do
    {
      id: 'spec/foo/baz_spec.rb:3',
      metadata: {
        file_path: 'spec/foo/baz_spec.rb',
        line_number: 3,
        full_description: 'hello GitLab'
      },
      execution_result: double(status: 'passed', exception: nil)
    }
  end

  before do
    # Stub these env variables otherwise specs don't behave the same on the CI
    stub_env('CI_JOB_URL', nil)
    stub_env('FLAKY_RSPEC_SUITE_REPORT_PATH', nil)
  end

  describe '#initialize' do
    shared_examples 'a valid Listener instance' do
      let(:expected_suite_flaky_examples) { {} }

      it 'returns a valid Listener instance' do
        listener = described_class.new

        expect(listener.suite_flaky_examples.to_h).to eq(expected_suite_flaky_examples)
        expect(listener.flaky_examples).to eq({})
      end
    end

    context 'when no report file exists' do
      it_behaves_like 'a valid Listener instance'
    end

    context 'when FLAKY_RSPEC_SUITE_REPORT_PATH is set' do
      let(:report_file_path) { 'foo/report.json' }

      before do
        stub_env('FLAKY_RSPEC_SUITE_REPORT_PATH', report_file_path)
      end

      context 'when report file exists' do
        before do
          allow(File).to receive(:exist?).with(report_file_path).and_return(true)
        end

        it 'delegates the load to RspecFlaky::Report' do
          report = Gitlab::RspecFlaky::Report
            .new(Gitlab::RspecFlaky::FlakyExamplesCollection.new(suite_flaky_example_report))

          expect(Gitlab::RspecFlaky::Report).to receive(:load).with(report_file_path).and_return(report)
          expect(described_class.new.suite_flaky_examples.to_h).to eq(report.flaky_examples.to_h)
        end
      end

      context 'when report file does not exist' do
        before do
          allow(File).to receive(:exist?).with(report_file_path).and_return(false)
        end

        it 'return an empty hash' do
          expect(Gitlab::RspecFlaky::Report).not_to receive(:load)
          expect(described_class.new.suite_flaky_examples.to_h).to eq({})
        end
      end
    end
  end

  describe '#example_passed' do
    let(:rspec_example) { double(new_example_attrs) }
    let(:notification) { double(example: rspec_example) }
    let(:listener) { described_class.new(suite_flaky_example_report.to_json) }

    shared_examples 'a non-flaky example' do
      it 'does not change the flaky examples hash' do
        expect { listener.example_passed(notification) }
          .not_to change { listener.flaky_examples }
      end
    end

    shared_examples 'an existing flaky example' do
      let(:expected_flaky_example) do
        {
          example_id: 'spec/foo/bar_spec.rb:2',
          file: 'spec/foo/bar_spec.rb',
          line: 2,
          description: 'hello world',
          first_flaky_at: 1234,
          last_attempts_count: 2,
          flaky_reports: 2,
          feature_category: nil,
          last_flaky_job: nil
        }
      end

      it 'changes the flaky examples hash' do
        new_example = Gitlab::RspecFlaky::Example.new(rspec_example)

        travel_to(Time.now + 42) do
          the_future = Time.now
          expect { listener.example_passed(notification) }
            .to change { listener.flaky_examples[new_example.uid].to_h }
          expect(listener.flaky_examples[new_example.uid].to_h)
            .to eq(expected_flaky_example.merge(last_flaky_at: the_future))
        end
      end
    end

    shared_examples 'a new flaky example' do
      let(:expected_flaky_example) do
        {
          example_id: 'spec/foo/baz_spec.rb:3',
          file: 'spec/foo/baz_spec.rb',
          line: 3,
          description: 'hello GitLab',
          last_attempts_count: 2,
          flaky_reports: 1,
          feature_category: nil,
          last_flaky_job: nil
        }
      end

      it 'changes the all flaky examples hash' do
        new_example = Gitlab::RspecFlaky::Example.new(rspec_example)

        travel_to(Time.now + 42) do
          the_future = Time.now
          expect { listener.example_passed(notification) }
            .to change { listener.flaky_examples[new_example.uid].to_h }
          expect(listener.flaky_examples[new_example.uid].to_h)
            .to eq(expected_flaky_example.merge(first_flaky_at: the_future, last_flaky_at: the_future))
        end
      end
    end

    describe 'when the RSpec example does not respond to attempts' do
      it_behaves_like 'a non-flaky example'
    end

    describe 'when the RSpec example has 1 attempt' do
      let(:rspec_example) { double(new_example_attrs.merge(attempts: 1)) }

      it_behaves_like 'a non-flaky example'
    end

    describe 'when the RSpec example has 2 attempts' do
      let(:rspec_example) { double(new_example_attrs.merge(attempts: 2)) }

      it_behaves_like 'a new flaky example'

      context 'with an existing flaky example' do
        let(:rspec_example) { double(already_flaky_example_attrs.merge(attempts: 2)) }

        it_behaves_like 'an existing flaky example'
      end
    end
  end

  describe '#dump_summary' do
    subject { listener.dump_summary(nil) }

    let(:listener) { described_class.new(suite_flaky_example_report.to_json) }
    let(:new_flaky_rspec_example) { double(new_example_attrs.merge(attempts: 2)) }
    let(:already_flaky_rspec_example) { double(already_flaky_example_attrs.merge(attempts: 2)) }
    let(:notification_new_flaky_rspec_example) { double(example: new_flaky_rspec_example) }
    let(:notification_already_flaky_rspec_example) { double(example: already_flaky_rspec_example) }

    before do
      allow(Kernel).to receive(:warn)
    end

    context 'when not flaky tests were found' do
      it 'prints a message in the console' do
        allow(Kernel).to receive(:warn).and_call_original

        expect { subject }.to output(
          %r{0 known flaky example\(s\) detected\. Writing this to rspec/flaky/report\.json}
        ).to_stderr
      end
    end

    context 'when existing flaky tests were found' do
      before do
        listener.example_passed(notification_already_flaky_rspec_example)
      end

      it 'does write them in the correct report' do
        report = double

        expect(Gitlab::RspecFlaky::Report).to receive(:new).with(listener.flaky_examples).and_return(report)
        expect(report).to receive(:write).with(Gitlab::RspecFlaky::Config.flaky_examples_report_path)

        subject
      end

      it 'prints a message in the console' do
        allow(Kernel).to receive(:warn).and_call_original

        expect { subject }.to output(
          %r{1 known flaky example\(s\) detected\. Writing this to rspec/flaky/report\.json}
        ).to_stderr
      end
    end

    context 'when a report file path is set by FLAKY_RSPEC_REPORT_PATH' do
      it 'delegates the writes to RspecFlaky::Report' do
        listener.example_passed(notification_new_flaky_rspec_example)
        listener.example_passed(notification_already_flaky_rspec_example)

        report1 = double
        report2 = double

        expect(Gitlab::RspecFlaky::Report).to receive(:new).with(listener.flaky_examples).and_return(report1)
        expect(report1).to receive(:write).with(Gitlab::RspecFlaky::Config.flaky_examples_report_path)

        expect(Gitlab::RspecFlaky::Report)
          .to receive(:new).with(listener.__send__(:new_flaky_examples)).and_return(report2)
        expect(report2).to receive(:write).with(Gitlab::RspecFlaky::Config.new_flaky_examples_report_path)

        subject
      end
    end
  end
end
