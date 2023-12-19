# frozen_string_literal: true

RSpec.describe QA::Runtime::Path do
  describe '.qa_root' do
    it 'returns the fully-qualified path to the QA directory' do
      expect(described_class.qa_root).to eq(File.expand_path('../../', __dir__))
    end
  end

  describe '.fixtures_path' do
    it 'returns the fully-qualified path to the fixtures directory' do
      expect(described_class.fixtures_path).to eq(File.expand_path('../../qa/fixtures', __dir__))
    end
  end

  describe '.fixture' do
    it 'returns the fully-qualified path to a fixture file' do
      expect(described_class.fixture('foo', 'bar')).to eq(File.expand_path('../../qa/fixtures/foo/bar', __dir__))
    end
  end

  describe '.qa_tmp' do
    it 'returns the fully-qualified path to the qa tmp directory' do
      expect(described_class.qa_tmp('foo', 'bar')).to eq(File.expand_path('../../tmp/foo/bar', __dir__))
    end
  end
end
