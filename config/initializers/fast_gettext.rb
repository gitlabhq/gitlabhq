FastGettext.add_text_domain 'gitlab', path: 'locale', type: :po
FastGettext.default_text_domain = 'gitlab'
FastGettext.default_available_locales = Gitlab::I18n::AVAILABLE_LANGUAGES.keys
