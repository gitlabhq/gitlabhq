require 'spec_helper'

describe Gitlab::SlashCommands::Run do
  describe '.available?' do
    it 'returns true when builds are enabled for the project' do
      project = double(:project, builds_enabled?: true)

      allow(Gitlab::Chat)
        .to receive(:available?)
        .and_return(true)

      expect(described_class.available?(project)).to eq(true)
    end

    it 'returns false when builds are disabled for the project' do
      project = double(:project, builds_enabled?: false)

      expect(described_class.available?(project)).to eq(false)
    end

    it 'returns false when chatops is not available' do
      allow(Gitlab::Chat)
        .to receive(:available?)
        .and_return(false)

      project = double(:project, builds_enabled?: true)

      expect(described_class.available?(project)).to eq(false)
    end
  end

  describe '.allowed?' do
    it 'returns true when the user can create a pipeline' do
      project = create(:project)

      expect(described_class.allowed?(project, project.creator)).to eq(true)
    end

    it 'returns false when the user can not create a pipeline' do
      project = create(:project)
      user = create(:user)

      expect(described_class.allowed?(project, user)).to eq(false)
    end
  end

  describe '#execute' do
    let(:chat_name) { create(:chat_name) }
    let(:project) { create(:project) }

    let(:command) do
      described_class.new(project, chat_name, response_url: 'http://example.com')
    end

    context 'when a pipeline could not be scheduled' do
      it 'returns an error' do
        expect_any_instance_of(Gitlab::Chat::Command)
          .to receive(:try_create_pipeline)
          .and_return(nil)

        expect_any_instance_of(Gitlab::SlashCommands::Presenters::Run)
          .to receive(:failed_to_schedule)
          .with('foo')

        command.execute(command: 'foo', arguments: '')
      end
    end

    context 'when a pipeline could be created but the chat service was not supported' do
      it 'returns an error' do
        build = double(:build)
        pipeline = double(
          :pipeline,
          builds: double(:relation, take: build),
          persisted?: true
        )

        expect_any_instance_of(Gitlab::Chat::Command)
          .to receive(:try_create_pipeline)
          .and_return(pipeline)

        expect(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(build)
          .and_return(nil)

        expect_any_instance_of(Gitlab::SlashCommands::Presenters::Run)
          .to receive(:unsupported_chat_service)

        command.execute(command: 'foo', arguments: '')
      end
    end

    context 'using a valid pipeline' do
      it 'schedules the pipeline' do
        responder = double(:responder, scheduled_output: 'hello')
        build = double(:build)
        pipeline = double(
          :pipeline,
          builds: double(:relation, take: build),
          persisted?: true
        )

        expect_any_instance_of(Gitlab::Chat::Command)
          .to receive(:try_create_pipeline)
          .and_return(pipeline)

        expect(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(build)
          .and_return(responder)

        expect_any_instance_of(Gitlab::SlashCommands::Presenters::Run)
          .to receive(:in_channel_response)
          .with(responder.scheduled_output)

        command.execute(command: 'foo', arguments: '')
      end
    end
  end
end
