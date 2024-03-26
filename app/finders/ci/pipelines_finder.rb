# frozen_string_literal: true

module Ci
  class PipelinesFinder
    include UpdatedAtFilter

    attr_reader :project, :pipelines, :params, :current_user

    ALLOWED_INDEXED_COLUMNS = %w[id status ref updated_at user_id].freeze
    ALLOWED_SCOPES = {
      RUNNING: 'running',
      PENDING: 'pending',
      FINISHED: 'finished',
      BRANCHES: 'branches',
      TAGS: 'tags'
    }.freeze

    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @pipelines = project.all_pipelines
      @params = params
    end

    def execute
      return Ci::Pipeline.none unless Ability.allowed?(current_user, :read_pipeline, project)

      items = pipelines
      items = items.no_child unless params[:iids].present?
      items = by_iids(items)
      items = by_scope(items)
      items = by_status(items)
      items = by_ref(items)
      items = by_sha(items)
      items = by_username(items)
      items = by_yaml_errors(items)
      items = by_updated_at(items)
      items = by_source(items)
      items = by_name(items)

      sort_items(items)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def ids_for_ref(refs)
      pipelines.where(ref: refs).group(:ref).select('max(id)')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def from_ids(ids)
      pipelines.unscoped.where(project_id: project.id, id: ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def branches
      project.repository.branch_names
    end

    def tags
      project.repository.tag_names
    end

    def by_iids(items)
      if params[:iids].present?
        items.for_iid(params[:iids])
      else
        items
      end
    end

    def by_scope(items)
      case params[:scope]
      when ALLOWED_SCOPES[:RUNNING]
        items.running
      when ALLOWED_SCOPES[:PENDING]
        items.pending
      when ALLOWED_SCOPES[:FINISHED]
        items.finished
      when ALLOWED_SCOPES[:BRANCHES]
        from_ids(ids_for_ref(branches))
      when ALLOWED_SCOPES[:TAGS]
        from_ids(ids_for_ref(tags))
      else
        items
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def by_status(items)
      return items unless Ci::HasStatus::AVAILABLE_STATUSES.include?(params[:status])

      items.where(status: params[:status])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def by_source(items)
      return items unless ::Ci::Pipeline.sources.key?(params[:source])

      items.with_pipeline_source(params[:source])
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def by_ref(items)
      if params[:ref].present?
        items.where(ref: params[:ref])
      else
        items
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def by_sha(items)
      if params[:sha].present?
        items.where(sha: params[:sha])
      else
        items
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def by_username(items)
      return items unless params[:username].present?

      user_id = User.by_username(params[:username]).pluck_primary_key.first
      return Ci::Pipeline.none unless user_id

      items.where(user_id: user_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def by_yaml_errors(items)
      case Gitlab::Utils.to_boolean(params[:yaml_errors])
      when true
        items.where.not(yaml_errors: nil)
      when false
        items.where(yaml_errors: nil)
      else
        items
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def by_name(items)
      return items unless params[:name].present?

      items.for_name(params[:name])
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def sort_items(items)
      order_by = if ALLOWED_INDEXED_COLUMNS.include?(params[:order_by])
                   params[:order_by]
                 else
                   :id
                 end

      sort = if /\A(ASC|DESC)\z/i.match?(params[:sort])
               params[:sort]
             else
               :desc
             end

      items.order(order_by => sort)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
