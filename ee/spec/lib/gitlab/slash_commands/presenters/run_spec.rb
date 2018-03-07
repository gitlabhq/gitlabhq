require 'spec_helper'

describe Gitlab::SlashCommands::Presenters::Run do
  let(:presenter) { described_class.new }

  describe '#present' do
    context 'when no builds are present' do
      it 'returns an error' do
        builds = double(:builds, take: nil)
        pipeline = double(:pipeline, builds: builds)

        expect(presenter)
          .to receive(:unsupported_chat_service)

        presenter.present(pipeline)
      end
    end

    context 'when a responder could be found' do
      it 'returns the output for a scheduled pipeline' do
        responder = double(:responder, scheduled_output: 'hello')
        build = double(:build)
        builds = double(:builds, take: build)
        pipeline = double(:pipeline, builds: builds)

        allow(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(build)
          .and_return(responder)

        expect(presenter)
          .to receive(:in_channel_response)
          .with('hello')

        presenter.present(pipeline)
      end
    end

    context 'when a responder could not be found' do
      it 'returns an error' do
        build = double(:build)
        builds = double(:builds, take: build)
        pipeline = double(:pipeline, builds: builds)

        allow(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(build)
          .and_return(nil)

        expect(presenter)
          .to receive(:unsupported_chat_service)

        presenter.present(pipeline)
      end
    end
  end

  describe '#unsupported_chat_service' do
    it 'returns an ephemeral response' do
      expect(presenter)
        .to receive(:ephemeral_response)
        .with(text: /Sorry, this chat service is currently not supported/)

      presenter.unsupported_chat_service
    end
  end

  describe '#failed_to_schedule' do
    it 'returns an ephemeral response' do
      expect(presenter)
        .to receive(:ephemeral_response)
        .with(text: /The command could not be scheduled/)

      presenter.failed_to_schedule('foo')
    end
  end
end
