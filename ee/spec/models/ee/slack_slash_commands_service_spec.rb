require 'spec_helper'

describe SlackSlashCommandsService do
  describe '#chat_responder' do
    it 'returns the responder to use for Slack' do
      expect(described_class.new.chat_responder)
        .to eq(Gitlab::Chat::Responder::Slack)
    end
  end
end
