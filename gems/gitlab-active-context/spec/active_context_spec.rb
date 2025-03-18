# frozen_string_literal: true

RSpec.describe ActiveContext do
  it "has a version number" do
    expect(ActiveContext::VERSION).not_to be_nil
  end

  describe '.configure' do
    let(:connection_model) { double('ConnectionModel') }

    it 'creates a new instance with the provided configuration block' do
      ActiveContext.configure do |config|
        config.enabled = true
        config.connection_model = connection_model
        config.logger = ::Logger.new(nil)
      end

      expect(ActiveContext::Config.enabled?).to be true
      expect(ActiveContext::Config.connection_model).to eq(connection_model)
      expect(ActiveContext::Config.logger).to be_a(::Logger)
    end
  end

  describe '.adapter' do
    it 'returns nil when not configured' do
      allow(ActiveContext::Config).to receive(:enabled?).and_return(false)
      expect(described_class.adapter).to be_nil
    end

    it 'returns configured adapter' do
      connection = double('Connection')
      connection_model = double('ConnectionModel', active: connection)
      adapter_class = ActiveContext::Databases::Postgresql::Adapter

      allow(ActiveContext::Config).to receive_messages(enabled?: true, connection_model: connection_model)
      allow(connection).to receive_messages(adapter_class: adapter_class.name,
        options: { host: 'localhost', port: 5432, database: 'test_db' })

      expect(adapter_class).to receive(:new).with(connection,
        options: connection.options).and_return(instance_double(adapter_class))

      described_class.adapter
    end
  end
end
