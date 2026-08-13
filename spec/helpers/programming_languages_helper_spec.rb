# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProgrammingLanguagesHelper, feature_category: :source_code_management do
  describe '.search_language_placeholder' do
    let(:programming_language) { build(:programming_language, name: 'Ruby') }

    before do
      allow(helper).to receive(:programming_languages).and_return([programming_language])
    end

    context 'with no `language_name` param' do
      it 'returns a placeholder' do
        expect(helper.search_language_placeholder).to eq(_('Language'))
      end
    end

    context 'with a matching `language_name` param' do
      it 'returns the canonical language name for lowercase and mixed-case input', :aggregate_failures do
        allow(helper).to receive(:params).and_return({ language_name: 'ruby' })
        expect(helper.search_language_placeholder).to eq('Ruby')

        allow(helper).to receive(:params).and_return({ language_name: 'rUbY' })
        expect(helper.search_language_placeholder).to eq('Ruby')
      end
    end

    context 'with an unknown `language_name` param' do
      before do
        allow(helper).to receive(:params).and_return({ language_name: 'unknown' })
      end

      it 'returns a placeholder' do
        expect(helper.search_language_placeholder).to eq(_('Language'))
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
    let(:language) { build(:programming_language, name: 'Ruby') }

    context 'when language name matches case-insensitively' do
      it 'returns `is-active` for lowercase and mixed-case input', :aggregate_failures do
        allow(helper).to receive(:params).and_return({ language_name: 'ruby' })
        expect(helper.language_state_class(language)).to be('is-active')

        allow(helper).to receive(:params).and_return({ language_name: 'rUbY' })
        expect(helper.language_state_class(language)).to be('is-active')
      end
    end

    context 'when language name does not match' do
      before do
        allow(helper).to receive(:params).and_return({ language_name: 'Python' })
      end

      it 'returns ``' do
        expect(helper.language_state_class(language)).to be('')
      end
    end

    context 'without a language name param' do
      before do
        allow(helper).to receive(:params).and_return({})
      end

      it 'returns ``' do
        expect(helper.language_state_class(language)).to be('')
      end
    end
  end
end
