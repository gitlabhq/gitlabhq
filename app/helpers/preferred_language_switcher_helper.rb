# frozen_string_literal: true

module PreferredLanguageSwitcherHelper
  SWITCHER_MINIMUM_TRANSLATION_LEVEL = 90

  def ordered_selectable_locales
    highly_translated_languages = Gitlab::I18n.selectable_locales(SWITCHER_MINIMUM_TRANSLATION_LEVEL)
    # see https://docs.gitlab.com/ee/development/i18n/externalization.html#adding-a-new-language
    # for translation standards
    locale_list = highly_translated_languages.filter_map do |code, language|
      percentage = Gitlab::I18n.percentage_translated_for(code)
      {
        value: code,
        percentage: percentage,
        text: language.split('-').last.strip
      }
    end

    locale_list.sort_by { |item| item[:percentage] }.reverse
  end
end
