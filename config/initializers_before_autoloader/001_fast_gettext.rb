# frozen_string_literal: true

FastGettext.add_text_domain 'gitlab',
                            path: File.join(Rails.root, 'locale'),
                            type: :po,
                            ignore_fuzzy: true
FastGettext.default_text_domain = 'gitlab'
FastGettext.default_locale = :en
