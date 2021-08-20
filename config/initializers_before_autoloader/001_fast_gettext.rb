# frozen_string_literal: true

translation_repositories = [
  FastGettext::TranslationRepository.build(
    'gitlab',
    path: File.join(Rails.root, 'locale'),
    type: :po,
    ignore_fuzzy: true
  )
]

Gitlab.jh do
  translation_repositories.unshift(
    FastGettext::TranslationRepository.build(
      'gitlab',
      path: File.join(Rails.root, 'jh', 'locale'),
      type: :po,
      ignore_fuzzy: true
    )
  )
end

FastGettext.add_text_domain(
  'gitlab',
  type: :chain,
  chain: translation_repositories,
  ignore_fuzzy: true
)

FastGettext.default_text_domain = 'gitlab'
FastGettext.default_locale = :en
