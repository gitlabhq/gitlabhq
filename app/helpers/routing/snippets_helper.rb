# frozen_string_literal: true

module Routing
  module SnippetsHelper
    def gitlab_snippet_path(snippet, *args)
      if snippet.is_a?(ProjectSnippet)
        project_snippet_path(snippet.project, snippet, *args)
      else
        new_args = snippet_query_params(snippet, *args)
        snippet_path(snippet, *new_args)
      end
    end

    def gitlab_snippet_url(snippet, *args)
      if snippet.is_a?(ProjectSnippet)
        project_snippet_url(snippet.project, snippet, *args)
      else
        new_args = snippet_query_params(snippet, *args)
        snippet_url(snippet, *new_args)
      end
    end

    def gitlab_dashboard_snippets_path(snippet, *args)
      if snippet.is_a?(ProjectSnippet)
        project_snippets_path(snippet.project, *args)
      else
        dashboard_snippets_path
      end
    end

    def gitlab_raw_snippet_path(snippet, *args)
      if snippet.is_a?(ProjectSnippet)
        raw_project_snippet_path(snippet.project, snippet, *args)
      else
        new_args = snippet_query_params(snippet, *args)
        raw_snippet_path(snippet, *new_args)
      end
    end

    def gitlab_raw_snippet_url(snippet, *args)
      if snippet.is_a?(ProjectSnippet)
        raw_project_snippet_url(snippet.project, snippet, *args)
      else
        new_args = snippet_query_params(snippet, *args)
        raw_snippet_url(snippet, *new_args)
      end
    end

    def gitlab_raw_snippet_blob_url(snippet, path, ref = nil, **options)
      params = {
        snippet_id: snippet,
        ref: ref || snippet.default_branch,
        path: path
      }

      if snippet.is_a?(ProjectSnippet)
        project_snippet_blob_raw_url(snippet.project, **params, **options)
      else
        snippet_blob_raw_url(**params, **options)
      end
    end

    def gitlab_raw_snippet_blob_path(snippet, path, ref = nil, **options)
      gitlab_raw_snippet_blob_url(snippet, path, ref, only_path: true, **options)
    end

    def gitlab_snippet_notes_path(snippet, *args)
      new_args = snippet_query_params(snippet, *args)
      snippet_notes_path(snippet, *new_args)
    end

    def gitlab_snippet_notes_url(snippet, *args)
      new_args = snippet_query_params(snippet, *args)
      snippet_notes_url(snippet, *new_args)
    end

    def gitlab_snippet_note_path(snippet, note, *args)
      new_args = snippet_query_params(snippet, *args)
      snippet_note_path(snippet, note, *new_args)
    end

    def gitlab_snippet_note_url(snippet, note, *args)
      new_args = snippet_query_params(snippet, *args)
      snippet_note_url(snippet, note, *new_args)
    end

    def gitlab_toggle_award_emoji_snippet_note_path(snippet, note, *args)
      new_args = snippet_query_params(snippet, *args)
      toggle_award_emoji_snippet_note_path(snippet, note, *new_args)
    end

    def gitlab_toggle_award_emoji_snippet_note_url(snippet, note, *args)
      new_args = snippet_query_params(snippet, *args)
      toggle_award_emoji_snippet_note_url(snippet, note, *new_args)
    end

    def gitlab_toggle_award_emoji_snippet_path(snippet, *args)
      new_args = snippet_query_params(snippet, *args)
      toggle_award_emoji_snippet_path(snippet, *new_args)
    end

    def gitlab_toggle_award_emoji_snippet_url(snippet, *args)
      new_args = snippet_query_params(snippet, *args)
      toggle_award_emoji_snippet_url(snippet, *new_args)
    end

    def preview_markdown_path(parent, *args)
      return group_preview_markdown_path(parent, *args) if parent.is_a?(Group)

      if @snippet.is_a?(PersonalSnippet)
        preview_markdown_snippets_path
      else
        project_preview_markdown_path(parent, *args)
      end
    end

    def toggle_award_emoji_personal_snippet_path(...)
      toggle_award_emoji_snippet_path(...)
    end

    def toggle_award_emoji_project_project_snippet_path(...)
      toggle_award_emoji_project_snippet_path(...)
    end

    def toggle_award_emoji_project_project_snippet_url(...)
      toggle_award_emoji_project_snippet_url(...)
    end

    private

    def snippet_query_params(snippet, *args)
      opts = case args.last
             when Hash
               args.pop
             when ActionController::Parameters
               args.pop.to_h
             else
               {}
             end

      args << opts
    end
  end
end
