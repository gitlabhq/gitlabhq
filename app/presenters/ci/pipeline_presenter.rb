# frozen_string_literal: true

module Ci
  class PipelinePresenter < Gitlab::View::Presenter::Delegated
    include Gitlab::Utils::StrongMemoize
    include SafeFormatHelper

    delegator_override_with Gitlab::Utils::StrongMemoize # This module inclusion is expected. See https://gitlab.com/gitlab-org/gitlab/-/issues/352884.

    # We use a class method here instead of a constant, allowing EE to redefine
    # the returned `Hash` more easily.
    def self.failure_reasons
      { unknown_failure: 'The reason for the pipeline failure is unknown.',
        config_error: 'The pipeline failed due to an error on the CI/CD configuration file.',
        external_validation_failure: 'The external pipeline validation failed.',
        user_not_verified: 'The pipeline failed due to the user not being verified.',
        size_limit_exceeded: 'The pipeline size limit was exceeded.',
        job_activity_limit_exceeded: 'The pipeline job activity limit was exceeded.',
        deployments_limit_exceeded: 'The pipeline deployments limit was exceeded.',
        project_deleted: 'The project associated with this pipeline was deleted.',
        filtered_by_rules: Ci::Pipeline.rules_failure_message,
        filtered_by_workflow_rules: Ci::Pipeline.workflow_rules_failure_message }
    end

    presents ::Ci::Pipeline, as: :pipeline

    delegator_override :failed_builds
    def failed_builds
      return [] unless can?(current_user, :read_build, pipeline)

      strong_memoize(:failed_builds) do
        pipeline.builds.latest.failed
      end
    end

    delegator_override :failure_reason
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

    def localized_names
      {
        merge_train: s_('Pipeline|Merge train pipeline'),
        merged_result: s_('Pipeline|Merged results pipeline'),
        detached: s_('Pipeline|Merge request pipeline')
      }.freeze
    end

    def event_type_name
      # Currently, `merge_request_event_type` is the only source to name pipelines
      # but this could be extended with the other types in the future.
      localized_names.fetch(pipeline.merge_request_event_type, s_('Pipeline|Pipeline'))
    end

    delegator_override :coverage
    def coverage
      return unless pipeline.coverage.present?

      '%.2f' % pipeline.coverage
    end

    def ref_text
      if pipeline.detached_merge_request_pipeline?
        safe_format(_("Related merge request %{link_to_merge_request} to merge %{link_to_merge_request_source_branch}"), link_to_merge_request: link_to_merge_request, link_to_merge_request_source_branch: link_to_merge_request_source_branch)
      elsif pipeline.merged_result_pipeline?
        safe_format(_("Related merge request %{link_to_merge_request} to merge %{link_to_merge_request_source_branch} into %{link_to_merge_request_target_branch}"), link_to_merge_request: link_to_merge_request, link_to_merge_request_source_branch: link_to_merge_request_source_branch, link_to_merge_request_target_branch: link_to_merge_request_target_branch)
      elsif all_related_merge_requests.any?
        (_("%{count} related %{pluralized_subject}: %{links}") % {
          count: all_related_merge_requests.count,
          pluralized_subject: n_('merge request', 'merge requests', all_related_merge_requests.count),
          links: all_related_merge_request_links.join(', ')
        }).html_safe
      elsif pipeline.ref && pipeline.ref_exists?
        safe_format(_("For %{link_to_pipeline_ref}"), link_to_pipeline_ref: link_to_pipeline_ref)
      elsif pipeline.ref
        safe_format(_("For %{ref}"), ref: plain_ref_name)
      end
    end

    def link_to_pipeline_ref
      ApplicationController.helpers.link_to(pipeline.ref,
        project_commits_path(pipeline.project, pipeline.ref),
        class: "ref-container gl-link")
    end

    def link_to_merge_request
      return unless merge_request_presenter

      ApplicationController.helpers.link_to(merge_request_presenter.to_reference,
        project_merge_request_path(merge_request_presenter.project, merge_request_presenter),
        class: 'mr-iid ref-container')
    end

    def link_to_merge_request_source_branch
      merge_request_presenter&.source_branch_link
    end

    def link_to_merge_request_target_branch
      merge_request_presenter&.target_branch_link
    end

    def downloadable_path_for_report_type(file_type)
      if (job_artifact = batch_lookup_report_artifact_for_file_type(file_type)) &&
          can?(current_user, :read_build, job_artifact.job)
        download_project_job_artifacts_path(
          job_artifact.project,
          job_artifact.job,
          file_type: file_type,
          proxy: true)
      end
    end

    def triggered_by_path
      pipeline.child? ? project_pipeline_path(pipeline.triggered_by_pipeline.project, pipeline.triggered_by_pipeline) : ''
    end

    private

    def plain_ref_name
      ApplicationController.helpers.content_tag(:span, pipeline.ref, class: 'ref-name')
    end

    def merge_request_presenter
      strong_memoize(:merge_request_presenter) do
        if pipeline.merge_request?
          pipeline.merge_request.present(current_user: current_user)
        end
      end
    end

    def all_related_merge_request_links
      all_related_merge_requests.map do |merge_request|
        mr_path = project_merge_request_path(merge_request.project, merge_request)

        ApplicationController.helpers.link_to "#{merge_request.to_reference} #{merge_request.title}", mr_path, class: 'mr-iid'
      end
    end

    def all_related_merge_requests
      strong_memoize(:all_related_merge_requests) do
        if pipeline.ref && can?(current_user, :read_merge_request, pipeline.project)
          pipeline.all_merge_requests_by_recency
        else
          []
        end
      end
    end
  end
end

Ci::PipelinePresenter.prepend_mod_with('Ci::PipelinePresenter')
