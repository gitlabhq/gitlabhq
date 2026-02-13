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

  private

  def preloaded_relations(preload_statuses: true, preload_downstream_statuses: true, **options)
    disable_failed_builds = options.delete(:disable_failed_builds)
    disable_manual_and_scheduled_actions = options[:disable_manual_and_scheduled_actions]

    manual_and_scheduled_actions_relations =
      if disable_manual_and_scheduled_actions
        {
          manual_actions: [],
          scheduled_actions: []
        }
      else
        {
          manual_actions: [:metadata, :job_definition],
          scheduled_actions: [:metadata, :job_definition]
        }
      end

    [
      :pipeline_metadata,
      :pipeline_schedule,
      :cancelable_statuses,
      :retryable_builds,
      :stages,
      :trigger,
      :user,
      (:latest_statuses if preload_statuses),
      (:limited_failed_builds if disable_failed_builds),
      {
        **(disable_failed_builds ? {} : { failed_builds: %i[project metadata] }),
        **manual_and_scheduled_actions_relations,
        merge_request: {
          source_project: [:route, { namespace: :route }],
          target_project: [:route, { namespace: :route }]
        },
        pending_builds: :project,
        project: [
          :route,
          { namespace: [:route, :namespace_settings_with_ancestors_inherited_settings] }
        ],
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
