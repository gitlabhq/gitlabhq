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

  def snippet_badge(snippet)
    return unless attrs = snippet_badge_attributes(snippet)

    icon_name, text = attrs
    tag.span(class: %w[badge badge-gray]) do
      concat(sprite_icon(icon_name, size: 14, css_class: 'gl-vertical-align-middle'))
      concat(' ')
      concat(text)
    end
  end

  def snippet_badge_attributes(snippet)
    if snippet.private?
      ['lock', _('private')]
    end
  end

  def embedded_raw_snippet_button(snippet, blob)
    return if blob.empty? || blob.binary? || blob.stored_externally?

    link_to(external_snippet_icon('doc-code'),
            gitlab_raw_snippet_blob_url(snippet, blob.path),
            class: 'gl-button btn btn-default',
            target: '_blank',
            rel: 'noopener noreferrer',
            title: 'Open raw')
  end

  def embedded_snippet_download_button(snippet, blob)
    link_to(external_snippet_icon('download'),
            gitlab_raw_snippet_blob_url(snippet, blob.path, nil, inline: false),
            class: 'gl-button btn btn-default',
            target: '_blank',
            title: 'Download',
            rel: 'noopener noreferrer')
  end

  def snippet_file_count(snippet)
    file_count = snippet.statistics&.file_count

    return unless file_count&.nonzero?

    tooltip = n_('%d file', '%d files', file_count) % file_count

    tag.span(class: 'file_count', title: tooltip, data: { toggle: 'tooltip', container: 'body' }) do
      concat(sprite_icon('documents', css_class: 'gl-vertical-align-middle'))
      concat(' ')
      concat(file_count)
    end
  end

  def project_snippets_award_api_path(snippet)
    if Feature.enabled?(:improved_emoji_picker, snippet.project, default_enabled: :yaml)
      api_v4_projects_snippets_award_emoji_path(id: snippet.project.id, snippet_id: snippet.id)
    end
  end
end
