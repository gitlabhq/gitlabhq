# frozen_string_literal: true

module RepositoryLanguagesHelper
  def repository_languages_bar(languages)
    return if languages.none?

    content_tag :div, class: 'progress repository-languages-bar' do
      safe_join(languages.map { |lang| language_progress(lang) })
    end
  end

  def language_progress(lang)
    content_tag :div, nil,
      class: "progress-bar has-tooltip",
      style: "width: #{lang.share}%; background-color:#{lang.color}",
      title: lang.name
  end
end
