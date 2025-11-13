# frozen_string_literal: true

module RapidDiffs
  class CommitAppComponent < AppComponent
    delegate :discussions_endpoint, :user_permissions, :noteable_type, :preview_markdown_endpoint, :markdown_docs_path,
      to: :presenter

    protected

    def app_data
      {
        **super,
        user_permissions: user_permissions,
        discussions_endpoint: discussions_endpoint,
        noteable_type: noteable_type,
        preview_markdown_endpoint: preview_markdown_endpoint,
        markdown_docs_path: markdown_docs_path
      }
    end

    def prefetch_endpoints
      [*super, discussions_endpoint]
    end
  end
end
