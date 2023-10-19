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
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 16384).and_call_original
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
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 16384).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(10)
        end
      end

      context 'when last_lines is set to a negative number' do
        let(:args) { { last_lines: -10 } }

        it 'shows the last line of trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 1, max_size: 16384).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(1)
        end
      end

      context 'when last_lines is set to 10' do
        let(:args) { { last_lines: 10 } }

        it 'shows the correct trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 16384).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(10)
        end
      end

      context 'when last_lines is set to 150' do
        let(:args) { { last_lines: 150 } }

        it 'shows the last 100 lines of trace contents' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 100, max_size: 16384).and_call_original
          end

          is_expected.to eq expected_html_trace_contents(100)
        end
      end
    end

    context 'when trace contains long lines' do
      before do
        # Creates lines of "aaaaaaaa...aaaaaaaa"
        job.trace.set((1..20).map { (1..1024).map { "a" }.join("") }.join("\n"))
      end

      context 'when last_lines is lower than 16KB' do
        let(:args) { {} }

        it 'shows the whole lines' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 16384).and_call_original
          end

          is_expected.to eq "<span>#{(1..10).map { (1..1024).map { 'a' }.join('') }.join('<br/>')}</span>"
        end
      end

      context 'when last_lines is higher than 16KB' do
        let(:args) { { last_lines: 20 } }

        it 'shows only the latest byte' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 20, max_size: 16384).and_call_original
          end

          is_expected.to eq "<span>#{(1..1009).map { 'a' }.join('')}<br/>" \
                            "#{(1..15).map { (1..1024).map { 'a' }.join('') }.join('<br/>')}</span>"
        end
      end

      context 'when trace is cut in middle of a line' do
        let(:args) { {} }

        before do
          stub_const('Types::Ci::JobTraceType::MAX_SIZE_B', 1536)
        end

        it 'shows only the latest byte' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 1536).and_call_original
          end

          is_expected.to eq "<span>#{(1..511).map { 'a' }.join('')}<br/>#{(1..1024).map { 'a' }.join('')}</span>"
        end
      end

      context 'when trace is cut at end of a line' do
        let(:args) { {} }

        before do
          stub_const('Types::Ci::JobTraceType::MAX_SIZE_B', 2050)
        end

        it 'shows only the latest byte' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 2050).and_call_original
          end

          is_expected.to eq "<span><br/>#{(1..2).map { (1..1024).map { 'a' }.join('') }.join('<br/>')}</span>"
        end
      end
    end

    context 'when trace contains multi-bytes UTF-8' do
      before do
        # Creates lines of 4 pound symbol, pound symbol is 2 byte wise in UTF-8
        # Append an "a" (1 byte character) at the end to cut in the middle of UTF-8
        job.trace.set((1..20).map { (1..4).map { "£" }.join("") }.join("\n"))
      end

      context 'when cut in the middle of a codepoint' do
        before do
          stub_const('Types::Ci::JobTraceType::MAX_SIZE_B', 5)
        end

        let(:args) { {} }

        it 'shows a single "invalid utf-8" symbol' do
          expect_next_instance_of(Gitlab::Ci::Trace) do |trace|
            expect(trace).to receive(:html).with(last_lines: 10, max_size: 5).and_call_original
          end

          is_expected.to eq "<span>�££</span>"
        end
      end
    end
  end
end
