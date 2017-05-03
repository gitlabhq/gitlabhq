module Gitlab
  module I18n
    extend self

    AVAILABLE_LANGUAGES = {
      en: 'English',
      es: 'Español',
      de: 'Deutsch'
    }.freeze

    def available_locales
      AVAILABLE_LANGUAGES.keys
    end
  end
end
