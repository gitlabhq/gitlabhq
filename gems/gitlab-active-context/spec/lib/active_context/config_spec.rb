# frozen_string_literal: true

RSpec.describe ActiveContext::Config do
  let(:logger) { ::Logger.new(nil) }
  let(:connection_model) { double('ConnectionModel') }

  before do
    described_class.configure do |config|
      config.enabled = nil
    end
  end

  describe '.configure' do
    it 'creates a new instance with the provided configuration block' do
      described_class.configure do |config|
        config.enabled = true
        config.connection_model = connection_model
        config.logger = logger
      end

      expect(described_class.enabled?).to be true
      expect(described_class.connection_model).to eq(connection_model)
      expect(described_class.logger).to eq(logger)
    end
  end

  describe '.enabled?' do
    context 'when enabled is not set' do
      it 'returns false' do
        expect(described_class.enabled?).to be false
      end
    end

    context 'when enabled is set to true' do
      before do
        described_class.configure do |config|
          config.enabled = true
        end
      end

      it 'returns true' do
        expect(described_class.enabled?).to be true
      end
    end
  end

  describe '.current' do
    context 'when no instance exists' do
      before do
        described_class.instance_variable_set(:@instance, nil)
      end

      it 'returns a new Cfg struct' do
        expect(described_class.current).to be_a(ActiveContext::Config::Cfg)
        expect(described_class.current.enabled).to be_nil
      end
    end

    context 'when an instance exists' do
      let(:test_config) { double('Config') }

      before do
        config_instance = instance_double(described_class)
        allow(config_instance).to receive(:config).and_return(test_config)
        described_class.instance_variable_set(:@instance, config_instance)
      end

      after do
        described_class.configure { |config| config.enabled = nil }
      end

      it 'returns the config from the instance' do
        expect(described_class.current).to eq(test_config)
      end
    end
  end

  describe '.connection_model' do
    before do
      stub_const('Ai::ActiveContext::Connection', Class.new)
    end

    context 'when connection_model is not set' do
      it 'returns the default model' do
        expect(described_class.connection_model).to eq(::Ai::ActiveContext::Connection)
      end
    end

    context 'when connection_model is set' do
      let(:custom_model) { Class.new }

      before do
        described_class.configure do |config|
          config.connection_model = custom_model
        end
      end

      it 'returns the configured connection model' do
        expect(described_class.connection_model).to eq(custom_model)
      end
    end
  end

  describe '.collection_model' do
    before do
      stub_const('Ai::ActiveContext::Collection', Class.new)
    end

    context 'when collection_model is not set' do
      it 'returns the default model' do
        expect(described_class.collection_model).to eq(::Ai::ActiveContext::Collection)
      end
    end

    context 'when collection_model is set' do
      let(:custom_model) { Class.new }

      before do
        described_class.configure do |config|
          config.collection_model = custom_model
        end
      end

      it 'returns the configured collection model' do
        expect(described_class.collection_model).to eq(custom_model)
      end
    end
  end

  describe '.logger' do
    context 'when logger is not set' do
      it 'returns a default stdout logger' do
        expect(described_class.logger).to be_a(Logger)
      end
    end

    context 'when logger is set' do
      before do
        described_class.configure do |config|
          config.logger = logger
        end
      end

      it 'returns the configured logger' do
        expect(described_class.logger).to eq(logger)
      end
    end
  end

  describe '.migrations_path' do
    before do
      stub_const('Rails', double('Rails', root: double('root', join: '/rails/root/path')))
    end

    context 'when migrations_path is not set' do
      it 'returns the default path' do
        expect(described_class.migrations_path).to eq('/rails/root/path')
      end
    end

    context 'when migrations_path is set' do
      let(:custom_path) { '/custom/path' }

      before do
        described_class.configure do |config|
          config.migrations_path = custom_path
        end
      end

      it 'returns the configured path' do
        expect(described_class.migrations_path).to eq(custom_path)
      end
    end
  end

  describe '.indexing_enabled?' do
    context 'when ActiveContext is not enabled' do
      before do
        described_class.configure do |config|
          config.enabled = false
          config.indexing_enabled = true
        end
      end

      it 'returns false' do
        expect(described_class.indexing_enabled?).to be false
      end
    end

    context 'when ActiveContext is enabled but indexing is not set' do
      before do
        described_class.configure do |config|
          config.enabled = true
          config.indexing_enabled = nil
        end
      end

      it 'returns false' do
        expect(described_class.indexing_enabled?).to be false
      end
    end

    context 'when both ActiveContext and indexing are enabled' do
      before do
        described_class.configure do |config|
          config.enabled = true
          config.indexing_enabled = true
        end
      end

      it 'returns true' do
        expect(described_class.indexing_enabled?).to be true
      end
    end
  end

  describe '.re_enqueue_indexing_workers?' do
    context 'when re_enqueue_indexing_workers is not set' do
      it 'returns false' do
        expect(described_class.re_enqueue_indexing_workers?).to be false
      end
    end

    context 'when re_enqueue_indexing_workers is set to true' do
      before do
        described_class.configure do |config|
          config.re_enqueue_indexing_workers = true
        end
      end

      it 'returns true' do
        expect(described_class.re_enqueue_indexing_workers?).to be true
      end
    end
  end

  describe '#initialize' do
    let(:config_block) { proc { |config| config.enabled = true } }
    let(:instance) { described_class.new(config_block) }

    it 'stores the config block' do
      expect(instance.instance_variable_get(:@config_block)).to eq(config_block)
    end
  end

  describe '#config' do
    let(:config_block) { proc { |config| config.enabled = true } }
    let(:instance) { described_class.new(config_block) }

    it 'creates a new struct and calls the config block on it' do
      result = instance.config
      expect(result).to be_a(ActiveContext::Config::Cfg)
      expect(result.enabled).to be true
    end
  end
end
