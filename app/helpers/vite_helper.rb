# frozen_string_literal: true

module ViteHelper
  def vite_enabled?
    # vite is not production ready yet
    return false if Rails.env.production?

    Gitlab::Utils.to_boolean(ViteRuby.env['VITE_ENABLED'], default: false)
  end

  def vite_page_entrypoint_paths(custom_action_name = nil)
    action_name = custom_action_name || controller.action_name
    action = case action_name
             when 'create' then 'new'
             when 'update' then 'edit'
             else action_name
             end

    parts = (controller.controller_path.split('/') << action)

    parts.map
         .with_index { |part, idx| "pages.#{(parts[0, idx] << part).join('.')}.js" }
  end

  def universal_stylesheet_link_tag(path, **options)
    return stylesheet_link_tag(path, **options) unless vite_enabled?

    options[:extname] = false

    stylesheet_link_tag(
      ViteRuby.instance.manifest.path_for("stylesheets/styles.#{path}.scss", type: :stylesheet),
      **options
    )
  end

  def universal_path_to_stylesheet(path, **options)
    return ActionController::Base.helpers.stylesheet_path(path, **options) unless vite_enabled?

    ViteRuby.instance.manifest.path_for("stylesheets/styles.#{path}.scss", **options)
  end
end
