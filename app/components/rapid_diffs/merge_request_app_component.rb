# frozen_string_literal: true

module RapidDiffs
  class MergeRequestAppComponent < ViewComponent::Base
    attr_reader :presenter

    delegate :mr_path, :project_path, :project_name, :code_review_enabled, :discussions_endpoint, :user_permissions,
      :noteable_type, :preview_markdown_endpoint, :markdown_docs_path, :register_path, :sign_in_path,
      :report_abuse_path, :versions, :linked_file, :suggestions_help_path,
      :default_suggestion_commit_message, :new_comment_template_paths, :coverage_endpoint, :codequality_endpoint,
      :sast_report_available, :initial_preparation?, :empty_state_type,
      to: :presenter

    def initialize(presenter)
      @presenter = presenter
    end

    private

    def extra_app_data
      {
        mr_path: mr_path,
        project_path: project_path,
        project_name: project_name,
        source_branch: presenter.resource.source_branch,
        iid: presenter.resource.iid,
        code_review_enabled: code_review_enabled,
        user_permissions: user_permissions,
        discussions_endpoint: discussions_endpoint,
        noteable_type: noteable_type,
        preview_markdown_endpoint: preview_markdown_endpoint,
        register_path: register_path,
        sign_in_path: sign_in_path,
        report_abuse_path: report_abuse_path,
        markdown_docs_path: markdown_docs_path,
        suggestions_help_path: suggestions_help_path,
        default_suggestion_commit_message: default_suggestion_commit_message,
        new_comment_template_paths: new_comment_template_paths,
        versions: versions,
        coverage_endpoint: coverage_endpoint,
        codequality_endpoint: codequality_endpoint,
        sast_report_available: sast_report_available,
        **check_out_branch_data
      }
    end

    def check_out_branch_data
      helpers.how_merge_modal_data(presenter.resource).slice(
        :is_fork, :source_project_path, :source_project_default_url, :reviewing_docs_path
      )
    end
  end
end
