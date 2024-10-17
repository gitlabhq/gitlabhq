# frozen_string_literal: true

RSpec.describe QA::Runtime::Namespace do
  include QA::Support::Helpers::StubEnv

  describe '.name' do
    context 'when CACHE_NAMESPACE_NAME is not defined' do
      before do
        stub_env('CACHE_NAMESPACE_NAME', nil)
      end

      it 'caches name by default' do
        name = described_class.name
        expect(described_class.name).to eq(name)
      end

      it 'does not cache name when reset_cache is true' do
        name = described_class.name
        expect(described_class.name(reset_cache: true)).not_to eq(name)
      end
    end

    context 'when CACHE_NAMESPACE_NAME is defined' do
      before do
        stub_env('CACHE_NAMESPACE_NAME', 'true')
      end

      it 'caches name by default' do
        name = described_class.name
        expect(described_class.name).to eq(name)
      end

      it 'caches name when reset_cache is false' do
        name = described_class.name
        expect(described_class.name(reset_cache: false)).to eq(name)
      end

      it 'does not cache name when reset_cache is true' do
        name = described_class.name
        expect(described_class.name(reset_cache: true)).not_to eq(name)
      end
    end
  end

  describe '.path' do
    before do
      allow(QA::Runtime::Scenario).to receive(:gitlab_address).and_return("http://gitlab.test")
      described_class.instance_variable_set(:@sandbox_name, nil)
    end

    it 'is always cached' do
      path = described_class.path
      expect(described_class.path).to eq(path)
    end
  end
end
