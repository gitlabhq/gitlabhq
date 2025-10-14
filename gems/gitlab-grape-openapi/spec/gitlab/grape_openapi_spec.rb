# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi do
  describe '.configuration' do
    subject(:configuration) { described_class.configuration }

    after do
      described_class.configuration = nil
    end

    it 'returns Configuration instance' do
      expect(configuration).to be_a(Gitlab::GrapeOpenapi::Configuration)
    end

    it 'memoizes configuration' do
      expect(configuration).to be(described_class.configuration)
    end
  end

  describe '.configuration=' do
    let(:custom_config) { Gitlab::GrapeOpenapi::Configuration.new }

    after do
      described_class.configuration = nil
    end

    it 'sets configuration' do
      described_class.configuration = custom_config

      expect(described_class.configuration).to be(custom_config)
    end
  end

  describe '.configure' do
    after do
      described_class.configuration = nil
    end

    it 'yields configuration block' do
      expect { |block| described_class.configure(&block) }
        .to yield_with_args(Gitlab::GrapeOpenapi::Configuration)
    end
  end

  describe '.generate' do
    let(:api_classes) { [] }
    let(:options) { {} }
    let(:generator) { instance_double(Gitlab::GrapeOpenapi::Generator) }

    it 'delegates to Generator' do
      expect(Gitlab::GrapeOpenapi::Generator).to receive(:new)
        .with(api_classes, options)
        .and_return(generator)
      expect(generator).to receive(:generate).and_return('{}')

      described_class.generate(api_classes, options)
    end
  end

  describe '::VERSION' do
    subject(:version) { described_class::VERSION }

    it { is_expected.to eq('0.1.0') }
  end
end
