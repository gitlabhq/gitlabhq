# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreferredLanguageSwitcherHelper do
  include StubLanguagesTranslationPercentage

  describe '#ordered_selectable_locales' do
    before do
      stub_languages_translation_percentage(es: 65, en: 100, zh_CN: described_class::SWITCHER_MINIMUM_TRANSLATION_LEVEL)
    end

    it 'returns filtered and ordered by translation level selectable locales' do
      expect(helper.ordered_selectable_locales).to eq(
        [
          { value: 'en', text: 'English', percentage: 100 },
          { value: 'zh_CN', text: "简体中文", percentage: described_class::SWITCHER_MINIMUM_TRANSLATION_LEVEL }
        ]
      )
    end
  end
end
