# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProgrammingLanguagesHelper do
  describe '.search_language_placeholder' do
    let(:programming_language) { build(:programming_language, id: 1, name: 'Ruby') }

    before do
      allow(helper).to receive(:programming_languages).and_return([programming_language])
    end

    context 'with no `language` param' do
      it 'returns a placeholder' do
        expect(helper.search_language_placeholder).to eq(_('Language'))
      end
    end

    context 'with a `language` param' do
      before do
        allow(helper).to receive(:params).and_return({ language: '2' })
      end

      context 'when invalid' do
        it 'returns a placeholder' do
          expect(helper.search_language_placeholder).to eq(_('Language'))
        end
      end

      context 'when valid' do
        let(:programming_language) { build(:programming_language, id: 2, name: 'Ruby') }

        it 'returns the chosen language' do
          expect(helper.search_language_placeholder).to eq('Ruby')
        end
      end
    end
  end

  describe '.programming_languages' do
    it 'callings ProgrammingLanguage.most_popular' do
      expect(ProgrammingLanguage).to receive(:most_popular)

      helper.programming_languages
    end
  end

  describe '.language_state_class' do
    let(:language) { build(:programming_language, id: language_id) }

    before do
      allow(helper).to receive(:params).and_return({ language: '1' })
    end

    context 'when language param matches' do
      let(:language_id) { 1 }

      it 'returns `is-active`' do
        expect(helper.language_state_class(language)).to be('is-active')
      end
    end

    context 'when language param does not match' do
      let(:language_id) { 2 }

      it 'returns ``' do
        expect(helper.language_state_class(language)).to be('')
      end
    end
  end
end
