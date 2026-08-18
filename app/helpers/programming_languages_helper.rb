# frozen_string_literal: true

module ProgrammingLanguagesHelper
  def search_language_placeholder
    placeholder = _('Language')

    return placeholder unless params[:language_name].present?

    programming_languages.find do |language|
      language.name.casecmp?(params[:language_name].to_s)
    end&.name || placeholder
  end

  def programming_languages
    @programming_languages ||= ProgrammingLanguage.most_popular
  end

  def language_state_class(language)
    language.name.casecmp?(params[:language_name].to_s) ? 'is-active' : ''
  end
end
