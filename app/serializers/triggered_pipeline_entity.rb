# frozen_string_literal: true

class TriggeredPipelineEntity < Grape::Entity
  include RequestAwareEntity

  MAX_EXPAND_DEPTH = 3

  expose :id
  expose :iid
  expose :active?, as: :active
  expose :coverage, unless: proc { options[:disable_coverage] }
  expose :name
  expose :source
  expose :user, using: UserEntity

  expose :source_job do
    expose :name do |pipeline|
      pipeline.source_job&.name
    end
    expose :retried do |pipeline|
      pipeline.source_job&.retried
    end
  end

  expose :path do |pipeline|
    project_pipeline_path(pipeline.project, pipeline)
  end

  expose :details do
    expose :detailed_status, as: :status, with: DetailedStatusEntity

    expose :stages,
      using: StageEntity,
      if: ->(_, opts) { can_read_details? && expand?(opts) }
  end

  expose :triggered_by_pipeline,
    as: :triggered_by, with: TriggeredPipelineEntity,
    if: ->(_, opts) { can_read_details? && expand_for_path?(opts) }

  expose :triggered_pipelines_with_preloads,
    as: :triggered, using: TriggeredPipelineEntity,
    if: ->(_, opts) { can_read_details? && expand_for_path?(opts) }

  expose :project, using: ProjectEntity

  private

  alias_method :pipeline, :object

  def can_read_details?
    can?(request.current_user, :read_pipeline, pipeline)
  end

  def detailed_status
    pipeline.detailed_status(request.current_user)
  end

  def expand?(opts)
    opts[:expanded].to_a.include?(pipeline.id)
  end

  def expand_for_path?(opts)
    # The `opts[:attr_path]` holds a list of all `exposes` in path
    # The check ensures that we always expand only `triggered_by`, `triggered_by`, ...
    # but not the `triggered_by`, `triggered` which would result in dead loop
    attr_path = opts[:attr_path]
    current_expose = attr_path.last

    # We expand at most to depth of MAX_DEPTH
    # We ensure that we expand in one direction: triggered_by,... or triggered, ...
    attr_path.length < MAX_EXPAND_DEPTH &&
      attr_path.all?(current_expose) &&
      expand?(opts)
  end
end
