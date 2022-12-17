# frozen_string_literal: true

module ProgrammingLanguagesHelper
  def search_language_placeholder
    placeholder = _('Language')

    return placeholder unless params[:language].present?

    programming_languages.find { |language| language.id.to_s == params[:language] }&.name ||
      placeholder
  end

  def programming_languages
    @programming_languages ||= ProgrammingLanguage.most_popular
  end

  def language_state_class(language)
    params[:language] == language.id.to_s ? 'is-active' : ''
  end
end
