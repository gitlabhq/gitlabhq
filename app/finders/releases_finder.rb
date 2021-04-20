# frozen_string_literal: true

class ReleasesFinder
  include Gitlab::Utils::StrongMemoize

  attr_reader :parent, :current_user, :params

  def initialize(parent, current_user = nil, params = {})
    @parent = parent
    @current_user = current_user
    @params = params

    params[:order_by] ||= 'released_at'
    params[:sort] ||= 'desc'
  end

  def execute(preload: true)
    return Release.none if projects.empty?

    releases = get_releases
    releases = by_tag(releases)
    releases = releases.preloaded if preload
    order_releases(releases)
  end

  private

  def get_releases
    Release.where(project_id: projects).where.not(tag: nil) # rubocop: disable CodeReuse/ActiveRecord
  end

  def include_subgroups?
    params.fetch(:include_subgroups, false)
  end

  def projects
    strong_memoize(:projects) do
      if parent.is_a?(Project)
        Ability.allowed?(current_user, :read_release, parent) ? [parent] : []
      elsif parent.is_a?(Group)
        accessible_projects
      end
    end
  end

  def accessible_projects
    projects = if include_subgroups?
                 Project.for_group_and_its_subgroups(parent)
               else
                 parent.projects
               end

    projects.select { |project| Ability.allowed?(current_user, :read_release, project) }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_tag(releases)
    return releases unless params[:tag].present?

    releases.where(tag: params[:tag])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def order_releases(releases)
    releases.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
  end
end
