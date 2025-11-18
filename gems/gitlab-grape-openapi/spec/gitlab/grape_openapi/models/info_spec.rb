# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Info do
  describe '#initialize' do
    it 'initializes with no options' do
      info = described_class.new

      expect(info.title).to be_nil
      expect(info.description).to be_nil
      expect(info.terms_of_service).to be_nil
      expect(info.version).to be_nil
    end

    it 'initializes with all options' do
      options = {
        title: 'My API',
        description: 'A detailed description',
        terms_of_service: 'https://example.com/terms'
      }

      info = described_class.new(**options)

      expect(info.title).to eq('My API')
      expect(info.description).to eq('A detailed description')
      expect(info.terms_of_service).to eq('https://example.com/terms')
    end

    it 'initializes with partial options' do
      info = described_class.new(title: 'Test API', description: 'Test description')

      expect(info.title).to eq('Test API')
      expect(info.description).to eq('Test description')
      expect(info.terms_of_service).to be_nil
    end

    it 'ignores unknown options' do
      info = described_class.new(title: 'Test API', unknown_option: 'value')

      expect(info.title).to eq('Test API')
      expect(info).not_to respond_to(:unknown_option)
    end
  end

  describe 'attr_accessor' do
    let(:info) { described_class.new }

    it 'allows setting and getting title' do
      info.title = 'New Title'
      expect(info.title).to eq('New Title')
    end

    it 'allows setting and getting description' do
      info.description = 'New Description'
      expect(info.description).to eq('New Description')
    end

    it 'allows setting and getting terms_of_service' do
      info.terms_of_service = 'https://example.com/new-terms'
      expect(info.terms_of_service).to eq('https://example.com/new-terms')
    end

    it 'allows setting and getting version' do
      info.version = '1.0.0'
      expect(info.version).to eq('1.0.0')
    end
  end

  describe '#to_h' do
    it 'returns empty hash when all attributes are nil' do
      info = described_class.new

      result = info.to_h

      expect(result).to eq({})
    end

    it 'returns hash with all non-nil attributes' do
      info = described_class.new(
        title: 'My API',
        description: 'API Description',
        terms_of_service: 'https://example.com/terms'
      )
      info.version = '2.0.0'

      result = info.to_h

      expect(result).to eq({
        title: 'My API',
        description: 'API Description',
        termsOfService: 'https://example.com/terms',
        version: '2.0.0'
      })
    end

    it 'excludes nil attributes from hash' do
      info = described_class.new(title: 'My API', description: 'Description')

      result = info.to_h

      expect(result).to eq({
        title: 'My API',
        description: 'Description'
      })
      expect(result).not_to have_key(:summary)
      expect(result).not_to have_key(:termsOfService)
      expect(result).not_to have_key(:version)
    end

    it 'converts terms_of_service to camelCase key' do
      info = described_class.new(terms_of_service: 'https://example.com/terms')

      result = info.to_h

      expect(result).to have_key(:termsOfService)
      expect(result).not_to have_key(:terms_of_service)
      expect(result[:termsOfService]).to eq('https://example.com/terms')
    end

    it 'includes empty strings in the hash' do
      info = described_class.new(title: '', description: 'Valid description')

      result = info.to_h

      expect(result).to eq({
        title: '',
        description: 'Valid description'
      })
    end

    it 'includes false values in the hash' do
      info = described_class.new(title: 'My API')
      info.version = false

      result = info.to_h

      expect(result).to eq({
        title: 'My API',
        version: false
      })
    end
  end
end
