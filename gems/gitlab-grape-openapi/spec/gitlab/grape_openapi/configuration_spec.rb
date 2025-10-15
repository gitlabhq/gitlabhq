# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Configuration do
  subject(:configuration) { described_class.new }

  describe '#api_version' do
    it 'has default value' do
      expect(configuration.api_version).to eq('v4')
    end
  end

  describe '#api_version=' do
    it 'sets api_version' do
      configuration.api_version = 'v5'

      expect(configuration.api_version).to eq('v5')
    end
  end

  describe '#servers' do
    it 'has default value' do
      expect(configuration.servers).to eq([])
    end
  end

  describe '#servers=' do
    it 'sets servers' do
      server = Gitlab::GrapeOpenapi::Models::Server.new(url: "http://example.com")
      configuration.servers = [server]
      expect(configuration.servers).to eq([server])
      expect(configuration.servers.first.url).to eq("http://example.com")
      expect(configuration.servers.first.description).to be_nil
    end
  end
end
