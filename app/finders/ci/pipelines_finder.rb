# frozen_string_literal: true

module Ci
  class PipelinesFinder
    attr_reader :project, :pipelines, :params, :current_user

    ALLOWED_INDEXED_COLUMNS = %w[id status ref updated_at user_id].freeze

    def initialize(project, current_user, params = {})
      @project = project
      @current_user = current_user
      @pipelines = project.all_pipelines
      @params = params
    end

    def execute
      unless Ability.allowed?(current_user, :read_pipeline, project)
        return Ci::Pipeline.none
      end

      items = pipelines
      items = items.no_child unless params[:iids].present?
      items = by_iids(items)
      items = by_scope(items)
      items = by_status(items)
      items = by_ref(items)
      items = by_sha(items)
      items = by_name(items)
      items = by_username(items)
      items = by_yaml_errors(items)
      items = by_updated_at(items)
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
      when 'running'
        items.running
      when 'pending'
        items.pending
      when 'finished'
        items.finished
      when 'branches'
        from_ids(ids_for_ref(branches))
      when 'tags'
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
    def by_name(items)
      if params[:name].present?
        items.joins(:user).where(users: { name: params[:name] })
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

    def by_updated_at(items)
      items = items.updated_before(params[:updated_before]) if params[:updated_before].present?
      items = items.updated_after(params[:updated_after]) if params[:updated_after].present?

      items
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def sort_items(items)
      order_by = if ALLOWED_INDEXED_COLUMNS.include?(params[:order_by])
                   params[:order_by]
                 else
                   :id
                 end

      sort = if params[:sort] =~ /\A(ASC|DESC)\z/i
               params[:sort]
             else
               :desc
             end

      items.order(order_by => sort)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
