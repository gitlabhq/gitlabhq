# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Mfe, feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  describe '.enabled?' do
    subject(:enabled) { described_class.enabled? }

    context 'when the enabled hook is a plain value' do
      where(:value) { [true, false] }

      with_them do
        before do
          described_class.configure { |config| config.enabled = value }
        end

        it { is_expected.to be(value) }
      end
    end

    context 'when the host application injects no hook' do
      it 'defaults to disabled' do
        expect(enabled).to be(false)
      end
    end

    context 'when the enabled hook is a callable' do
      before do
        described_class.configure { |config| config.enabled = -> { true } }
      end

      it { is_expected.to be(true) }
    end
  end

  describe '.registry_url' do
    subject(:registry_url) { described_class.registry_url }

    context 'when a registry url is injected' do
      before do
        described_class.configure do |config|
          config.registry_url = 'https://custom.example.com'
        end
      end

      it { is_expected.to eq('https://custom.example.com') }
    end

    context 'when the registry url is injected as a callable' do
      before do
        described_class.configure do |config|
          config.registry_url = -> { 'https://callable.example.com' }
        end
      end

      it { is_expected.to eq('https://callable.example.com') }
    end

    context 'when no registry url is injected' do
      it { is_expected.to eq(described_class::DEFAULT_REGISTRY_URL) }
    end

    # Contract: a nil registry_url from ANY source falls back to the default.
    # This is the one intentional divergence from the pre-extraction code
    # (which returned nil when the mfe config section existed but carried no
    # registry_url). The characterization harness for #616912 proved every
    # other input is byte-for-byte identical; these cases lock the fallback so
    # a future change cannot silently reintroduce a nil registry_url.
    context 'when the injected registry url resolves to nil' do
      where(:hook) { [nil, -> {}] }

      with_them do
        before do
          described_class.configure { |config| config.registry_url = hook }
        end

        it 'falls back to the default registry url' do
          expect(registry_url).to eq(described_class::DEFAULT_REGISTRY_URL)
        end
      end
    end
  end
end
