# frozen_string_literal: true

module ExploreHelper
  def filter_projects_path(options = {})
    exist_opts = {
      sort: params[:sort] || @sort,
      scope: params[:scope],
      group: params[:group],
      tag: params[:tag],
      visibility_level: params[:visibility_level],
      name: params[:name],
      personal: params[:personal],
      archived: params[:archived],
      shared: params[:shared],
      namespace_id: params[:namespace_id]
    }

    options = exist_opts.merge(options).delete_if { |key, value| value.blank? }
    request_path_with_options(options)
  end

  def filter_audit_path(options = {})
    exist_opts = {
      entity_type: params[:entity_type],
      entity_id: params[:entity_id],
      created_before: params[:created_before],
      created_after: params[:created_after],
      sort: params[:sort]
    }
    options = exist_opts.merge(options).delete_if { |key, value| value.blank? }
    request_path_with_options(options)
  end

  def filter_groups_path(options = {})
    request_path_with_options(options)
  end

  def explore_controller?
    controller.class.name.split("::").first == "Explore"
  end

  def explore_nav_links
    @explore_nav_links ||= get_explore_nav_links
  end

  def explore_nav_link?(link)
    explore_nav_links.include?(link)
  end

  def any_explore_nav_link?(links)
    links.any? { |link| explore_nav_link?(link) }
  end

  def public_visibility_restricted?
    Gitlab::VisibilityLevel.public_visibility_restricted?
  end

  private

  def get_explore_nav_links
    [:projects, :groups, :snippets]
  end

  def request_path_with_options(options = {})
    request.path + "?#{options.to_param}"
  end
end
