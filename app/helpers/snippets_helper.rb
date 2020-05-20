# frozen_string_literal: true

module SnippetsHelper
  def snippets_upload_path(snippet, user)
    return unless user

    if snippet&.persisted?
      upload_path('personal_snippet', id: snippet.id)
    else
      upload_path('user', id: user.id)
    end
  end

  def download_raw_snippet_button(snippet)
    link_to(icon('download'),
            gitlab_raw_snippet_path(snippet, inline: false),
            target: '_blank',
            rel: 'noopener noreferrer',
            class: "btn btn-sm has-tooltip",
            title: 'Download',
            data: { container: 'body' })
  end

  # Return the path of a snippets index for a user or for a project
  #
  # @returns String, path to snippet index
  def subject_snippets_path(subject = nil, opts = nil)
    if subject.is_a?(Project)
      project_snippets_path(subject, opts)
    else # assume subject === User
      dashboard_snippets_path(opts)
    end
  end

  # Get an array of line numbers surrounding a matching
  # line, bounded by min/max.
  #
  # @returns Array of line numbers
  def bounded_line_numbers(line, min, max, surrounding_lines)
    lower = line - surrounding_lines > min ? line - surrounding_lines : min
    upper = line + surrounding_lines < max ? line + surrounding_lines : max
    (lower..upper).to_a
  end

  def snippet_embed_tag(snippet)
    content_tag(:script, nil, src: gitlab_snippet_url(snippet, format: :js))
  end

  def snippet_embed_input(snippet)
    content_tag(:input,
                nil,
                type: :text,
                readonly: true,
                class: 'js-snippet-url-area snippet-embed-input form-control',
                data: { url: gitlab_snippet_url(snippet) },
                value: snippet_embed_tag(snippet),
                autocomplete: 'off')
  end

  def snippet_badge(snippet)
    return unless attrs = snippet_badge_attributes(snippet)

    css_class, text = attrs
    tag.span(class: %w[badge badge-gray]) do
      concat(tag.i(class: ['fa', css_class]))
      concat(' ')
      concat(text)
    end
  end

  def snippet_badge_attributes(snippet)
    if snippet.private?
      ['fa-lock', _('private')]
    end
  end

  def embedded_raw_snippet_button
    blob = @snippet.blob
    return if blob.empty? || blob.binary? || blob.stored_externally?

    link_to(external_snippet_icon('doc-code'),
            gitlab_raw_snippet_url(@snippet),
            class: 'btn',
            target: '_blank',
            rel: 'noopener noreferrer',
            title: 'Open raw')
  end

  def embedded_snippet_download_button
    link_to(external_snippet_icon('download'),
            gitlab_raw_snippet_url(@snippet, inline: false),
            class: 'btn',
            target: '_blank',
            title: 'Download',
            rel: 'noopener noreferrer')
  end
end
