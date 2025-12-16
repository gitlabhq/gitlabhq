# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::Tag do
  let(:tag) { described_class.new('audit_events') }

  describe '.normalize_tag_name' do
    subject(:normalized_name) { described_class.normalize_tag_name(tag_name) }

    context 'when tag_name is a simple underscore-separated string' do
      let(:tag_name) { 'audit_events' }

      it 'capitalizes and joins with spaces' do
        expect(normalized_name).to eq('Audit Events')
      end
    end

    context 'when tag_name is a single word' do
      let(:tag_name) { 'users' }

      it 'capitalizes the word' do
        expect(normalized_name).to eq('Users')
      end
    end

    context 'when tag_name has multiple underscores' do
      let(:tag_name) { 'user_audit_events_api' }

      it 'capitalizes all words and joins with spaces' do
        expect(normalized_name).to eq('User Audit Events Api')
      end
    end

    context 'when tag_overrides are configured' do
      let(:tag_name) { 'api_settings' }

      before do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = { 'api' => 'API' }
      end

      it 'applies the override for matching words' do
        expect(normalized_name).to eq('API Settings')
      end
    end

    context 'when tag_overrides has multiple entries' do
      let(:tag_name) { 'rest_api_for_ssh_keys' }

      before do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = {
          'api' => 'API',
          'ssh' => 'SSH',
          'rest' => 'REST'
        }
      end

      after do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = []
      end

      it 'applies all matching overrides' do
        expect(normalized_name).to eq('REST API For SSH Keys')
      end
    end

    context 'when tag_overrides is case-insensitive' do
      let(:tag_name) { 'my_api_endpoint' }

      before do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = { 'api' => 'API' }
      end

      it 'matches regardless of case in the normalized name' do
        expect(normalized_name).to eq('My API Endpoint')
      end
    end

    context 'when tag_overrides matches word boundaries' do
      let(:tag_name) { 'application_settings' }

      before do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = { 'app' => 'APP' }
      end

      after do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = []
      end

      it 'does not match partial words' do
        expect(normalized_name).to eq('Application Settings')
      end
    end

    context 'when tag_overrides is empty' do
      let(:tag_name) { 'api_settings' }

      before do
        Gitlab::GrapeOpenapi.configuration.tag_overrides = []
      end

      it 'returns the capitalized name without overrides' do
        expect(normalized_name).to eq('Api Settings')
      end
    end
  end

  describe '#initialize' do
    it 'sets the name' do
      expect(tag.name).to eq('Audit Events')
    end
  end

  describe '#to_h' do
    subject(:hash) { tag.to_h }

    context 'when description is present' do
      before do
        allow(tag).to receive(:description).and_return('A test tag description')
      end

      it 'returns a hash with name and description' do
        expect(hash).to eq({ name: 'Audit Events', description: 'A test tag description' })
      end
    end

    context 'when description is nil' do
      before do
        allow(tag).to receive(:description).and_return(nil)
      end

      it 'returns a hash with only name' do
        expect(hash).to eq({ name: 'Audit Events' })
      end
    end
  end

  describe '#description' do
    subject(:description) { tag.description }

    it 'returns a humanized description based on the tag name' do
      expect(description).to eq('Operations concerning Audit Events')
    end
  end
end
