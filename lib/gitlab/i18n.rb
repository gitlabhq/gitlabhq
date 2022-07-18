# frozen_string_literal: true

module Gitlab
  module I18n
    extend self

    AVAILABLE_LANGUAGES = {
      'bg' => 'Bulgarian - български',
      'cs_CZ' => 'Czech - čeština',
      'da_DK' => 'Danish - dansk',
      'de' => 'German - Deutsch',
      'en' => 'English',
      'eo' => 'Esperanto - esperanto',
      'es' => 'Spanish - español',
      'fil_PH' => 'Filipino',
      'fr' => 'French - français',
      'gl_ES' => 'Galician - galego',
      'id_ID' => 'Indonesian - Bahasa Indonesia',
      'it' => 'Italian - italiano',
      'ja' => 'Japanese - 日本語',
      'ko' => 'Korean - 한국어',
      'nb_NO' => 'Norwegian (Bokmål) - norsk (bokmål)',
      'nl_NL' => 'Dutch - Nederlands',
      'pl_PL' => 'Polish - polski',
      'pt_BR' => 'Portuguese (Brazil) - português (Brasil)',
      'ro_RO' => 'Romanian - română',
      'ru' => 'Russian - русский',
      'si_LK' => 'Sinhalese - සිංහල',
      'tr_TR' => 'Turkish - Türkçe',
      'uk' => 'Ukrainian - українська',
      'zh_CN' => 'Chinese, Simplified - 简体中文',
      'zh_HK' => 'Chinese, Traditional (Hong Kong) - 繁體中文 (香港)',
      'zh_TW' => 'Chinese, Traditional (Taiwan) - 繁體中文 (台灣)'
    }.freeze
    private_constant :AVAILABLE_LANGUAGES

    # Languages with less then MINIMUM_TRANSLATION_LEVEL% of available translations will not
    # be available in the UI.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/221012
    MINIMUM_TRANSLATION_LEVEL = 2

    # Currently monthly updated manually by ~group::import PM.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/18923
    TRANSLATION_LEVELS = {
      'bg' => 0,
      'cs_CZ' => 0,
      'da_DK' => 40,
      'de' => 15,
      'en' => 100,
      'eo' => 0,
      'es' => 37,
      'fil_PH' => 0,
      'fr' => 11,
      'gl_ES' => 0,
      'id_ID' => 0,
      'it' => 1,
      'ja' => 33,
      'ko' => 11,
      'nb_NO' => 26,
      'nl_NL' => 0,
      'pl_PL' => 4,
      'pt_BR' => 55,
      'ro_RO' => 100,
      'ru' => 28,
      'si_LK' => 11,
      'tr_TR' => 12,
      'uk' => 49,
      'zh_CN' => 99,
      'zh_HK' => 2,
      'zh_TW' => 4
    }.freeze
    private_constant :TRANSLATION_LEVELS

    def selectable_locales
      AVAILABLE_LANGUAGES.reject do |code, _name|
        percentage_translated_for(code) < MINIMUM_TRANSLATION_LEVEL
      end
    end

    def percentage_translated_for(code)
      TRANSLATION_LEVELS.fetch(code, 0)
    end

    def available_locales
      AVAILABLE_LANGUAGES.keys
    end

    def locale
      FastGettext.locale
    end

    def locale=(locale_string)
      requested_locale = locale_string || ::I18n.default_locale
      new_locale = FastGettext.set_locale(requested_locale)
      ::I18n.locale = new_locale
    end

    def use_default_locale
      FastGettext.set_locale(::I18n.default_locale)
      ::I18n.locale = ::I18n.default_locale
    end

    def with_locale(locale_string)
      original_locale = locale

      self.locale = locale_string
      yield
    ensure
      self.locale = original_locale
    end

    def with_user_locale(user, &block)
      with_locale(user&.preferred_language, &block)
    end

    def with_default_locale(&block)
      with_locale(::I18n.default_locale, &block)
    end
  end
end
