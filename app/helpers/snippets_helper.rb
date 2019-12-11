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

  # Returns a sorted set of lines to be included in a snippet preview.
  # This ensures matching adjacent lines do not display duplicated
  # surrounding code.
  #
  # @returns Array, unique and sorted.
  def matching_lines(lined_content, surrounding_lines, query)
    used_lines = []
    lined_content.each_with_index do |line, line_number|
      used_lines.concat bounded_line_numbers(
        line_number,
        0,
        lined_content.size,
        surrounding_lines
      ) if line.downcase.include?(query.downcase)
    end

    used_lines.uniq.sort
  end

  # 'Chunkify' entire snippet.  Splits the snippet data into matching lines +
  # surrounding_lines() worth of unmatching lines.
  #
  # @returns a hash with {snippet_object, snippet_chunks:{data,start_line}}
  def chunk_snippet(snippet, query, surrounding_lines = 3)
    lined_content = snippet.content.split("\n")
    used_lines = matching_lines(lined_content, surrounding_lines, query)

    snippet_chunk = []
    snippet_chunks = []
    snippet_start_line = 0
    last_line = -1

    # Go through each used line, and add consecutive lines as a single chunk
    # to the snippet chunk array.
    used_lines.each do |line_number|
      if last_line < 0
        # Start a new chunk.
        snippet_start_line = line_number
        snippet_chunk << lined_content[line_number]
      elsif last_line == line_number - 1
        # Consecutive line, continue chunk.
        snippet_chunk << lined_content[line_number]
      else
        # Non-consecutive line, add chunk to chunk array.
        snippet_chunks << {
          data: snippet_chunk.join("\n"),
          start_line: snippet_start_line + 1
        }

        # Start a new chunk.
        snippet_chunk = [lined_content[line_number]]
        snippet_start_line = line_number
      end

      last_line = line_number
    end
    # Add final chunk to chunk array
    snippet_chunks << {
      data: snippet_chunk.join("\n"),
      start_line: snippet_start_line + 1
    }

    # Return snippet with chunk array
    { snippet_object: snippet, snippet_chunks: snippet_chunks }
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
    tag.span(class: ['badge', 'badge-gray']) do
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
