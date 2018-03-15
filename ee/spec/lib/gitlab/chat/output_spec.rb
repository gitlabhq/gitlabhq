require 'spec_helper'

describe Gitlab::Chat::Output do
  let(:build) do
    create(:ci_build, pipeline: create(:ci_pipeline, source: :chat))
  end

  let(:output) { described_class.new(build) }

  describe '#to_s' do
    it 'returns the build output as a String' do
      trace = Gitlab::Ci::Trace.new(build)

      trace.set("echo hello\nhello")

      allow(build)
        .to receive(:trace)
        .and_return(trace)

      allow(output)
        .to receive(:read_offset_and_length)
        .and_return([0, 13])

      expect(output.to_s).to eq('he')
    end
  end

  describe '#read_offset_and_length' do
    context 'without the chat_reply trace section' do
      it 'falls back to using the build_script trace section' do
        expect(output)
          .to receive(:find_build_trace_section)
          .with('chat_reply')
          .and_return(nil)

        expect(output)
          .to receive(:find_build_trace_section)
          .with('build_script')
          .and_return({ name: 'build_script', byte_start: 1, byte_end: 4 })

        expect(output.read_offset_and_length).to eq([1, 3])
      end
    end

    context 'without the build_script trace section' do
      it 'raises MissingBuildSectionError' do
        expect { output.read_offset_and_length }
          .to raise_error(described_class::MissingBuildSectionError)
      end
    end

    context 'with the chat_reply trace section' do
      it 'returns the read offset and length as an Array' do
        trace = Gitlab::Ci::Trace.new(build)

        allow(build)
          .to receive(:trace)
          .and_return(trace)

        allow(trace)
          .to receive(:extract_sections)
          .and_return([{ name: 'chat_reply', byte_start: 1, byte_end: 4 }])

        expect(output.read_offset_and_length).to eq([1, 3])
      end
    end
  end

  describe '#without_executed_command_line' do
    it 'returns the input without the first line' do
      expect(output.without_executed_command_line("hello\nworld"))
        .to eq('world')
    end

    it 'returns an empty String when the input is empty' do
      expect(output.without_executed_command_line('')).to eq('')
    end

    it 'returns an empty String when the input consits of a single newline' do
      expect(output.without_executed_command_line("\n")).to eq('')
    end
  end

  describe '#find_build_trace_section' do
    it 'returns nil when no section could be found' do
      expect(output.find_build_trace_section('foo')).to be_nil
    end

    it 'returns the trace section when it could be found' do
      section = { name: 'chat_reply', byte_start: 1, byte_end: 4 }

      allow(output)
        .to receive(:trace_sections)
        .and_return([section])

      expect(output.find_build_trace_section('chat_reply')).to eq(section)
    end
  end
end
