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

    gl_badge_tag(text, icon: icon_name)
  end

  def snippet_badge_attributes(snippet)
    if snippet.private?
      ['lock', _('private')]
    end
  end

  def snippet_report_abuse_path(snippet)
    return unless snippet.submittable_as_spam_by?(current_user)

    mark_as_spam_snippet_path(snippet)
  end

  def embedded_raw_snippet_button(snippet, blob)
    return if blob.empty? || blob.binary? || blob.stored_externally?

    link_to(
      external_snippet_icon('doc-code'),
      gitlab_raw_snippet_blob_url(snippet, blob.path),
      class: 'gl-button btn btn-default',
      target: '_blank',
      rel: 'noopener noreferrer',
      title: 'Open raw'
    )
  end

  def embedded_snippet_download_button(snippet, blob)
    link_to(
      external_snippet_icon('download'),
      gitlab_raw_snippet_blob_url(snippet, blob.path, nil, inline: false),
      class: 'gl-button btn btn-default',
      target: '_blank',
      title: 'Download',
      rel: 'noopener noreferrer'
    )
  end

  def embedded_copy_snippet_button(blob)
    return unless blob.rendered_as_text?(ignore_errors: false)

    content_tag(
      :button,
      class: 'gl-button btn btn-default copy-to-clipboard-btn',
      title: 'Copy snippet contents',
      onclick: "copyToClipboard('.blob-content[data-blob-id=\"#{blob.id}\"] > pre')"
    ) do
      external_snippet_icon('copy-to-clipboard')
    end
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
    api_v4_projects_snippets_award_emoji_path(id: snippet.project.id, snippet_id: snippet.id)
  end
end
