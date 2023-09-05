# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTrace'], feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:job) { create(:ci_build) }

  it 'has the correct fields' do
    expected_fields = [:html_summary]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'htmlSummary' do
    subject(:resolved_field) { resolve_field(:html_summary, job.trace, args: args) }

    context 'when trace contains few lines' do
      before do
        job.trace.set('BUILD TRACE')
      end

      context 'when last_lines is set to 10' do
        let(:args) { { last_lines: 10 } }

        it 'shows the correct trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10).and_call_original
          end

          is_expected.to eq('<span>BUILD TRACE</span>')
        end
      end
    end

    context 'when trace contains many lines' do
      before do
        job.trace.set((1..200).map { |i| "Line #{i}" }.join("\n"))
      end

      def expected_html_trace_contents(line_count)
        "<span>#{((200 - (line_count - 1))..200).map { |i| "Line #{i}" }.join('<br/>')}</span>"
      end

      context 'when last_lines is not set' do
        let(:args) { {} }

        it 'shows the last 10 lines of trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(10)
        end
      end

      context 'when last_lines is set to a negative number' do
        let(:args) { { last_lines: -10 } }

        it 'shows the last line of trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 1).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(1)
        end
      end

      context 'when last_lines is set to 10' do
        let(:args) { { last_lines: 10 } }

        it 'shows the correct trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(10)
        end
      end

      context 'when last_lines is set to 150' do
        let(:args) { { last_lines: 150 } }

        it 'shows the last 100 lines of trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 100).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(100)
        end
      end
    end
  end
end
