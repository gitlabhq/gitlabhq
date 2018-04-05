module Gitlab
  module I18n
    extend self

    AVAILABLE_LANGUAGES = {
      'en' => 'English',
      'es' => 'Español',
      'de' => 'Deutsch',
      'fr' => 'Français',
      'pt_BR' => 'Português (Brasil)',
      'zh_CN' => '简体中文',
      'zh_HK' => '繁體中文 (香港)',
      'zh_TW' => '繁體中文 (臺灣)',
      'bg' => 'български',
      'ru' => 'Русский',
      'eo' => 'Esperanto',
      'it' => 'Italiano',
      'uk' => 'Українська',
      'ja' => '日本語',
      'ko' => '한국어',
      'nl_NL' => 'Nederlands',
      'tr_TR' => 'Türkçe',
      'id_ID' => 'Bahasa Indonesia',
      'fil_PH' => 'Filipino'
    }.freeze

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
