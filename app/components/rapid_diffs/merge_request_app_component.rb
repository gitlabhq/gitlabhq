# frozen_string_literal: true

module RapidDiffs
  class MergeRequestAppComponent < ViewComponent::Base
    attr_reader :presenter

    delegate :mr_path, :code_review_enabled, :discussions_endpoint, :user_permissions,
      :noteable_type, :preview_markdown_endpoint, :markdown_docs_path, :register_path, :sign_in_path,
      :report_abuse_path, to: :presenter

    def initialize(presenter)
      @presenter = presenter
    end

    private

    def extra_app_data
      {
        mr_path: mr_path,
        code_review_enabled: code_review_enabled,
        user_permissions: user_permissions,
        discussions_endpoint: discussions_endpoint,
        noteable_type: noteable_type,
        preview_markdown_endpoint: preview_markdown_endpoint,
        register_path: register_path,
        sign_in_path: sign_in_path,
        report_abuse_path: report_abuse_path,
        markdown_docs_path: markdown_docs_path
      }
    end
  end
end
