# frozen_string_literal: true

module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    include Gitlab::Utils::StrongMemoize
    include ActionView::Helpers::UrlHelper

    # We use a class method here instead of a constant, allowing EE to redefine
    # the returned `Hash` more easily.
    def self.failure_reasons
      { config_error: 'CI/CD YAML configuration error!' }
    end

    presents :pipeline

    def failed_builds
      return [] unless can?(current_user, :read_build, pipeline)

      strong_memoize(:failed_builds) do
        pipeline.builds.latest.failed
      end
    end

    def failure_reason
      return unless pipeline.failure_reason?

      self.class.failure_reasons[pipeline.failure_reason.to_sym] ||
        pipeline.failure_reason
    end

    def status_title
      if auto_canceled?
        "Pipeline is redundant and is auto-canceled by Pipeline ##{auto_canceled_by_id}"
      end
    end

    def ref_text
      if pipeline.detached_merge_request_pipeline?
        _("for %{link_to_merge_request} with %{link_to_merge_request_source_branch}").html_safe % { link_to_merge_request: link_to_merge_request, link_to_merge_request_source_branch: link_to_merge_request_source_branch }
      elsif pipeline.merge_request_pipeline?
        _("for %{link_to_merge_request} with %{link_to_merge_request_source_branch} into %{link_to_merge_request_target_branch}").html_safe % { link_to_merge_request: link_to_merge_request, link_to_merge_request_source_branch: link_to_merge_request_source_branch, link_to_merge_request_target_branch: link_to_merge_request_target_branch }
      elsif pipeline.ref
        if pipeline.ref_exists?
          _("for %{link_to_pipeline_ref}").html_safe % { link_to_pipeline_ref: link_to_pipeline_ref }
        else
          _("for %{ref}").html_safe % { ref: content_tag(:span, pipeline.ref, class: 'ref-name') }
        end
      end
    end

    def link_to_pipeline_ref
      link_to(pipeline.ref,
        project_commits_path(pipeline.project, pipeline.ref),
        class: "ref-name")
    end

    def link_to_merge_request
      return unless merge_request_presenter

      link_to(merge_request_presenter.to_reference,
        project_merge_request_path(merge_request_presenter.project, merge_request_presenter),
        class: 'mr-iid')
    end

    def link_to_merge_request_source_branch
      merge_request_presenter&.source_branch_link
    end

    def link_to_merge_request_target_branch
      merge_request_presenter&.target_branch_link
    end

    private

    def merge_request_presenter
      return unless pipeline.triggered_by_merge_request?

      @merge_request_presenter ||= pipeline.merge_request.present(current_user: current_user)
    end
  end
end
