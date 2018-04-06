require 'spec_helper'

describe Gitlab::Chat::Command do
  let(:chat_name) { create(:chat_name) }

  let(:command) do
    described_class.new(
      project: project,
      chat_name: chat_name,
      name: 'spinach',
      arguments: 'foo',
      channel: '123',
      response_url: 'http://example.com'
    )
  end

  describe '#try_create_pipeline' do
    let(:project) { create(:project) }

    it 'returns nil when the command is not valid' do
      expect(command)
        .to receive(:valid?)
        .and_return(false)

      expect(command.try_create_pipeline).to be_nil
    end

    it 'tries to create the pipeline when a command is valid' do
      expect(command)
        .to receive(:valid?)
        .and_return(true)

      expect(command)
        .to receive(:create_pipeline)

      command.try_create_pipeline
    end
  end

  describe '#create_pipeline' do
    let(:project) { create(:project, :test_repo) }
    let(:pipeline) { command.create_pipeline }

    before do
      stub_repository_ci_yaml_file(sha: project.commit.id)

      project.add_developer(chat_name.user)
    end

    it 'creates the pipeline' do
      expect(pipeline).to be_persisted
    end

    it 'creates the chat data for the pipeline' do
      expect(pipeline.chat_data).to be_an_instance_of(Ci::PipelineChatData)
    end

    it 'stores the chat name ID in the chat data' do
      expect(pipeline.chat_data.chat_name_id).to eq(chat_name.id)
    end

    it 'stores the response URL in the chat data' do
      expect(pipeline.chat_data.response_url).to eq('http://example.com')
    end

    it 'creates the environment variables for the pipeline' do
      vars = pipeline.variables.each_with_object({}) do |row, hash|
        hash[row.key] = row.value
      end

      expect(vars['CHAT_INPUT']).to eq('foo')
      expect(vars['CHAT_CHANNEL']).to eq('123')
    end
  end
end
