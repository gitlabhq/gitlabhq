# frozen_string_literal: true

module PreviewMarkdown
  extend ActiveSupport::Concern

  def preview_markdown
    result = PreviewMarkdownService.new(
      container: resource_parent,
      current_user: current_user,
      params: preview_markdown_params
    ).execute do |text|
      view_context.markdown(text, markdown_context_params)
    end

    render json: {
      body: result[:rendered_html],
      references: {
        users: result[:users],
        suggestions: SuggestionSerializer.new.represent_diff(result[:suggestions]),
        commands: view_context.markdown(result[:commands])
      }
    }
  end

  private

  def resource_parent
    @project
  end

  def projects_filter_params
    {
      issuable_reference_expansion_enabled: true,
      suggestions_filter_enabled: Gitlab::Utils.to_boolean(preview_markdown_params[:preview_suggestions])
    }
  end

  def timeline_events_filter_params
    {
      issuable_reference_expansion_enabled: true,
      pipeline: :'incident_management/timeline_event'
    }
  end

  def wikis_filter_params
    {
      pipeline: :wiki,
      wiki: wiki,
      page_slug: preview_markdown_params[:id],
      repository: wiki.repository,
      issuable_reference_expansion_enabled: true
    }
  end

  def markdown_context_params
    case controller_name
    when 'wikis'
      wiki_page = wiki.find_page(preview_markdown_params[:id])

      wikis_filter_params
    when 'snippets'        then { skip_project_check: true }
    when 'groups'          then { group: group, issuable_reference_expansion_enabled: true }
    when 'projects'        then projects_filter_params
    when 'timeline_events' then timeline_events_filter_params
    when 'organizations'   then { pipeline: :description }
    else {}
    end.merge(
      requested_path: preview_markdown_params[:path] || wiki_page&.path,
      ref: preview_markdown_params[:ref],
      # Disable comments in markdown for IE browsers because comments in IE
      # could allow script execution.
      allow_comments: !browser.ie?,
      no_header_anchors: no_header_anchors
    )
  end

  def no_header_anchors
    return true if preview_markdown_params[:target_type] == 'Commit'

    Gitlab::Utils.to_boolean(preview_markdown_params[:no_header_anchors])
  end

  def preview_markdown_params
    params.permit(:text, :preview_suggestions, :id, :path, :ref, :target_type, :target_id, :no_header_anchors)
  end
end
