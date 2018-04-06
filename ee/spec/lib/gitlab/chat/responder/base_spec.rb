require 'spec_helper'

describe Gitlab::Chat::Responder::Base do
  let(:project) { double(:project) }
  let(:pipeline) { double(:pipeline, project: project) }
  let(:build) { double(:build, pipeline: pipeline) }
  let(:responder) { described_class.new(build) }

  describe '#pipeline' do
    it 'returns the pipeline' do
      expect(responder.pipeline).to eq(pipeline)
    end
  end

  describe '#project' do
    it 'returns the project' do
      expect(responder.project).to eq(project)
    end
  end

  describe '#success' do
    it 'raises NotImplementedError' do
      expect { responder.success }.to raise_error(NotImplementedError)
    end
  end

  describe '#failure' do
    it 'raises NotImplementedError' do
      expect { responder.failure }.to raise_error(NotImplementedError)
    end
  end

  describe '#send_response' do
    it 'raises NotImplementedError' do
      expect { responder.send_response('hello') }
        .to raise_error(NotImplementedError)
    end
  end

  describe '#scheduled_output' do
    it 'raises NotImplementedError' do
      expect { responder.scheduled_output }
        .to raise_error(NotImplementedError)
    end
  end
end
