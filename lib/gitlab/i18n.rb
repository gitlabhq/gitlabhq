module Gitlab
  module I18n
    extend self

    AVAILABLE_LANGUAGES = {
      'en' => 'English',
      'es' => 'Español',
      'de' => 'Deutsch',
	  'zh_CN' => '简体中文',
	  'zh_HK' => '繁體中文(香港)',
	  'zh_TW' => '繁體中文(臺灣)'
    }.freeze

    def available_locales
      AVAILABLE_LANGUAGES.keys
    end

    def set_locale(current_user)
      requested_locale = current_user&.preferred_language || ::I18n.default_locale
      locale = FastGettext.set_locale(requested_locale)
      ::I18n.locale = locale
    end

    def reset_locale
      FastGettext.set_locale(::I18n.default_locale)
      ::I18n.locale = ::I18n.default_locale
    end
  end
end
