require 'spec_helper'

describe Gitlab::SlashCommands::Command do
  describe '.commands' do
    it 'includes EE specific commands' do
      expect(described_class.commands).to include(Gitlab::SlashCommands::Run)
    end
  end
end
