# frozen_string_literal: true

module RepositoryLanguagesHelper
  def repository_languages_bar(languages)
    return if languages.none?

    content_tag :div, class: 'progress repository-languages-bar js-show-on-project-root' do
      safe_join(languages.map { |lang| language_progress(lang) })
    end
  end

  def language_progress(lang)
    content_tag :div, nil,
      class: "progress-bar has-tooltip",
      style: "width: #{lang.share}%; background-color:#{lang.color}",
      data: { html: true },
      title: "<span class=\"repository-language-bar-tooltip-language\">#{escape_javascript(lang.name)}</span>&nbsp;<span class=\"repository-language-bar-tooltip-share\">#{lang.share.round(1)}%</span>"
  end
end
