# frozen_string_literal: true

class LabelsFinder < UnionFinder
  prepend FinderWithCrossProjectAccess
  include FinderWithGroupHierarchy
  include FinderMethods
  include Gitlab::Utils::StrongMemoize

  requires_cross_project_access unless: -> { project? }

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute(skip_authorization: false)
    @skip_authorization = skip_authorization
    items = find_union(item_ids, Label) || Label.none
    items = with_title(items)
    items = by_subscription(items)
    items = by_search(items)
    sort(items)
  end

  private

  attr_reader :current_user, :params, :skip_authorization

  # rubocop: disable CodeReuse/ActiveRecord
  def item_ids
    item_ids = []

    if project?
      if project
        if project.group.present?
          labels_table = Label.arel_table
          group_ids = group_ids_for(project.group)

          item_ids << Label.where(
            labels_table[:type].eq('GroupLabel').and(labels_table[:group_id].in(group_ids)).or(
              labels_table[:type].eq('ProjectLabel').and(labels_table[:project_id].eq(project.id))
            )
          )
        else
          item_ids << project.labels
        end
      end
    else
      if group?
        item_ids << Label.where(group_id: group_ids_for(group))
      end

      item_ids << Label.where(group_id: projects.group_ids)
      item_ids << Label.where(project_id: ids_user_can_read_labels(projects)) unless only_group_labels?
    end

    item_ids
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def sort(items)
    if params[:sort]
      items.order_by(params[:sort])
    else
      items.reorder(title: :asc)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def with_title(items)
    return items if title.nil?
    return items.none if title.blank?

    items.where(title: title)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_search(labels)
    return labels unless search?

    labels.search(params[:search])
  end

  def by_subscription(labels)
    labels.optionally_subscribed_by(subscriber_id)
  end

  def subscriber_id
    current_user&.id if subscribed?
  end

  def subscribed?
    params[:subscribed] == 'true'
  end

  def projects?
    params[:project_ids]
  end

  def only_group_labels?
    params[:only_group_labels]
  end

  def search?
    params[:search].present?
  end

  def title
    params[:title] || params[:name]
  end

  def project?
    params[:project].present? || params[:project_id].present?
  end

  def project
    return @project if defined?(@project)

    if project?
      @project = params[:project] || Project.find(params[:project_id])
      @project = nil unless authorized_to_read_item?(@project)
    else
      @project = nil
    end

    @project
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def projects
    return @projects if defined?(@projects)

    @projects = if skip_authorization
                  Project.all
                else
                  ProjectsFinder.new(params: { non_archived: true }, current_user: current_user).execute # rubocop: disable CodeReuse/Finder
                end

    if group?
      @projects = if params[:include_descendant_groups]
                    @projects.in_namespace(group.self_and_descendants.select(:id))
                  else
                    @projects.in_namespace(group.id)
                  end
    end

    @projects = @projects.where(id: params[:project_ids]) if projects?
    @projects = @projects.reorder(nil)

    @projects
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def read_permission
    :read_label
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def ids_user_can_read_labels(projects)
    Project.where(id: projects.select(:id)).ids_with_issuables_available_for(current_user)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
