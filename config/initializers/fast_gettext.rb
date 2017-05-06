FastGettext.add_text_domain 'gitlab', path: File.join(Rails.root, 'locale'), type: :po
FastGettext.default_text_domain = 'gitlab'
FastGettext.default_available_locales = Gitlab::I18n.available_locales

I18n.available_locales = Gitlab::I18n.available_locales
