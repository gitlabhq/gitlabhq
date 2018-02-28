FastGettext.add_text_domain 'gitlab',
                            path: File.join(Rails.root, 'locale'),
                            type: :po,
                            ignore_fuzzy: true
FastGettext.default_text_domain = 'gitlab'
FastGettext.default_available_locales = Gitlab::I18n.available_locales
FastGettext.default_locale = :en

I18n.available_locales = Gitlab::I18n.available_locales
