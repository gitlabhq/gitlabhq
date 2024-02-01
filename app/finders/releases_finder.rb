# frozen_string_literal: true

class ReleasesFinder
  include Gitlab::Utils::StrongMemoize
  include UpdatedAtFilter

  attr_reader :parent, :current_user, :params

  def initialize(parent, current_user = nil, params = {})
    @parent = Array.wrap(parent)
    @current_user = current_user
    @params = params

    params[:order_by] ||= 'released_at'
    params[:order_by_for_latest] ||= 'released_at'
    params[:sort] ||= 'desc'
  end

  def execute(preload: true)
    return Release.none if authorized_projects.empty?

    releases = params[:latest] ? get_latest_releases : get_releases
    releases = by_tag(releases)
    releases = by_updated_at(releases)
    releases = releases.preloaded if preload
    order_releases(releases)
  end

  private

  def get_releases
    Release.for_projects(authorized_projects).tagged
  end

  def get_latest_releases
    Release.latest_for_projects(authorized_projects, order_by: params[:order_by_for_latest]).tagged
  end

  def authorized_projects
    # Preload policy for all projects to avoid N+1 queries
    projects = Project.id_in(parent.map(&:id)).include_project_feature
    Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute

    projects.select { |project| authorized?(project) }
  end
  strong_memoize_attr :authorized_projects

  def order_releases(releases)
    releases.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
  end

  def authorized?(project)
    Ability.allowed?(current_user, :read_release, project)
  end

  def by_tag(releases)
    return releases unless params[:tag].present?

    releases.by_tag(params[:tag])
  end
end
