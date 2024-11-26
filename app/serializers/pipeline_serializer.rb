# frozen_string_literal: true

class PipelineSerializer < BaseSerializer
  include WithPagination
  entity PipelineDetailsEntity

  # rubocop: disable CodeReuse/ActiveRecord
  def represent(resource, opts = {})
    resource = resource.preload(preloaded_relations(**opts)) if resource.is_a?(ActiveRecord::Relation)
    resource = paginator.paginate(resource) if paginated?
    resource = Gitlab::Ci::Pipeline::Preloader.preload!(resource) if opts.delete(:preload)

    super(resource, opts)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def represent_status(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:status] }] })
    data.dig(:details, :status) || {}
  end

  def represent_stages(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:stages] }], preload: true })
    data.dig(:details, :stages) || []
  end

  private

  def preloaded_relations(preload_statuses: true, preload_downstream_statuses: true, **options)
    disable_failed_builds = options.delete(:disable_failed_builds)

    [
      :pipeline_metadata,
      :pipeline_schedule,
      :cancelable_statuses,
      :retryable_builds,
      :stages,
      :trigger_requests,
      :user,
      (:latest_statuses if preload_statuses),
      (:limited_failed_builds if disable_failed_builds),
      {
        **(disable_failed_builds ? {} : { failed_builds: %i[project metadata] }),
        manual_actions: :metadata,
        scheduled_actions: :metadata,
        merge_request: {
          source_project: [:route, { namespace: :route }],
          target_project: [:route, { namespace: :route }]
        },
        pending_builds: :project,
        project: [:route, { namespace: :route }],
        triggered_by_pipeline: [{ project: [:route, { namespace: :route }] }, :user],
        triggered_pipelines: [
          (:latest_statuses if preload_downstream_statuses),
          {
            project: [:route, { namespace: :route }]
          },
          :source_job,
          :user
        ].compact
      }
    ].compact
  end
end

PipelineSerializer.prepend_mod_with('PipelineSerializer')
