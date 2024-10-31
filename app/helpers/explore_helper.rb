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

    exist_opts[:language] = params[:language]

    options = exist_opts.merge(options).delete_if { |key, value| value.blank? }
    request_path_with_options(options)
  end

  def public_visibility_restricted?
    Gitlab::VisibilityLevel.public_visibility_restricted?
  end

  def projects_filter_items
    [
      { value: _('Any'), text: _('Any'), href: filter_projects_path(visibility_level: nil) },
      *Gitlab::VisibilityLevel.options.keys.map do |key|
        {
          value: key,
          text: key,
          href: filter_projects_path(visibility_level: Gitlab::VisibilityLevel.options[key])
        }
      end
    ]
  end

  def projects_filter_selected(visibility_level)
    visibility_level.present? ? visibility_level_label(visibility_level.to_i) : _('Any')
  end

  private

  def request_path_with_options(options = {})
    request.path + "?#{options.to_param}"
  end
end
