# frozen_string_literal: true

module Gitlab
  module I18n
    extend self

    AVAILABLE_LANGUAGES = {
      'bg' => 'Bulgarian - български',
      'cs_CZ' => 'Czech - čeština',
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
      'nl_NL' => 'Dutch - Nederlands',
      'pl_PL' => 'Polish - polski',
      'pt_BR' => 'Portuguese (Brazil) - português (Brasil)',
      'ru' => 'Russian - Русский',
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
      'bg' => 1,
      'cs_CZ' => 1,
      'de' => 17,
      'en' => 100,
      'eo' => 1,
      'es' => 38,
      'fil_PH' => 1,
      'fr' => 12,
      'gl_ES' => 1,
      'id_ID' => 0,
      'it' => 2,
      'ja' => 42,
      'ko' => 13,
      'nl_NL' => 1,
      'pl_PL' => 5,
      'pt_BR' => 21,
      'ru' => 29,
      'tr_TR' => 16,
      'uk' => 41,
      'zh_CN' => 67,
      'zh_HK' => 2,
      'zh_TW' => 3
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
