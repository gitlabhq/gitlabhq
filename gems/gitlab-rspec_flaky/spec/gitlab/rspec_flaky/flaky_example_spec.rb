# frozen_string_literal: true

require 'gitlab/rspec_flaky/flaky_example'

RSpec.describe Gitlab::RspecFlaky::FlakyExample, :aggregate_failures do
  include StubENV

  let(:example_attrs) do
    {
      example_id: 'spec/foo/bar_spec.rb:2',
      file: 'spec/foo/bar_spec.rb',
      line: 2,
      description: 'hello world',
      last_attempts_count: 2,
      feature_category: :feature_category
    }
  end

  before do
    # Stub these env variables otherwise specs don't behave the same on the CI
    stub_env('CI_JOB_URL', nil)
  end

  describe '#initialize', :freeze_time do
    shared_examples 'a valid FlakyExample instance' do
      let(:flaky_example) { described_class.new(args) }

      it 'returns valid attributes' do
        attrs = flaky_example.to_h

        expect(attrs[:uid]).to eq(example_attrs[:uid])
        expect(attrs[:file]).to eq(example_attrs[:file])
        expect(attrs[:line]).to eq(example_attrs[:line])
        expect(attrs[:description]).to eq(example_attrs[:description])
        expect(attrs[:feature_category]).to eq(example_attrs[:feature_category])
        expect(attrs[:first_flaky_at]).to eq(expected_first_flaky_at)
        expect(attrs[:last_flaky_at]).to eq(expected_last_flaky_at)
        expect(attrs[:last_attempts_count]).to eq(example_attrs[:last_attempts_count])
        expect(attrs[:flaky_reports]).to eq(expected_flaky_reports)
      end
    end

    context 'when given an Example.to_h' do
      it_behaves_like 'a valid FlakyExample instance' do
        let(:args) { example_attrs }
        let(:expected_first_flaky_at) { Time.now }
        let(:expected_last_flaky_at) { Time.now }
        let(:expected_flaky_reports) { 0 }
      end
    end
  end

  describe '#update!' do
    shared_examples 'an up-to-date FlakyExample instance' do
      let(:flaky_example) { described_class.new(args) }

      it 'sets the first_flaky_at if none exists' do
        args[:first_flaky_at] = nil

        freeze_time do
          flaky_example.update!(example_attrs)

          expect(flaky_example.to_h[:first_flaky_at]).to eq(Time.now)
        end
      end

      it 'maintains the first_flaky_at if exists' do
        flaky_example.update!(example_attrs)
        expected_first_flaky_at = flaky_example.to_h[:first_flaky_at]

        travel_to(Time.now + 42) do
          flaky_example.update!(example_attrs)
          expect(flaky_example.to_h[:first_flaky_at]).to eq(expected_first_flaky_at)
        end
      end

      it 'updates the last_flaky_at' do
        travel_to(Time.now + 42) do
          the_future = Time.now
          flaky_example.update!(example_attrs)

          expect(flaky_example.to_h[:last_flaky_at]).to eq(the_future)
        end
      end

      it 'updates the flaky_reports' do
        expected_flaky_reports = flaky_example.to_h[:first_flaky_at] ? flaky_example.to_h[:flaky_reports] + 1 : 1

        expect { flaky_example.update!(example_attrs) }.to change { flaky_example.to_h[:flaky_reports] }.by(1)
        expect(flaky_example.to_h[:flaky_reports]).to eq(expected_flaky_reports)
      end

      it 'updates the last_attempts_count' do
        example_attrs[:last_attempts_count] = 42
        flaky_example.update!(example_attrs)

        expect(flaky_example.to_h[:last_attempts_count]).to eq(42)
      end

      context 'when run on the CI' do
        let(:job_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/42' }

        before do
          stub_env('CI_JOB_URL', job_url)
        end

        it 'updates the last_flaky_job' do
          flaky_example.update!(example_attrs)

          expect(flaky_example.to_h[:last_flaky_job]).to eq(job_url)
        end
      end
    end

    context 'when given an Example hash' do
      it_behaves_like 'an up-to-date FlakyExample instance' do
        let(:args) { example_attrs }
      end
    end
  end

  describe '#to_h', :freeze_time do
    shared_examples 'a valid FlakyExample hash' do
      let(:additional_attrs) { {} }

      it 'returns a valid hash' do
        flaky_example = described_class.new(args)
        final_hash = example_attrs.merge(additional_attrs)

        expect(flaky_example.to_h).to eq(final_hash)
      end
    end

    context 'when given an Example hash' do
      let(:args) { example_attrs }

      it_behaves_like 'a valid FlakyExample hash' do
        let(:additional_attrs) do
          { first_flaky_at: Time.now, last_flaky_at: Time.now, last_flaky_job: nil, flaky_reports: 0 }
        end
      end
    end
  end
end
