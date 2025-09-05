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
          .filter do |name|
            # always truthy in dev mode for non-existing entrypoints
            # we return /* doesn't exist */ on the dev server for such false positives
            ViteRuby.instance.manifest.path_for(name)
          rescue ViteRuby::MissingEntrypointError
            # we don't know if an entrypoint exists for each of the controller action part
            # for example: it might be present for the last part but not for the first part
            #   - pages.merge_requests.js -> empty, error thrown
            #   - pages.merge_requests.edit.js -> found
            false
          end
  end

  def universal_stylesheet_link_tag(path, **options)
    return stylesheet_link_tag(path, **options) unless vite_enabled?

    options[:extname] = false

    vite_stylesheet_tag(css_entrypoint_name(path), **options)
  end

  def universal_path_to_stylesheet(path, **options)
    return ActionController::Base.helpers.stylesheet_path(path, **options) unless vite_enabled?

    ViteRuby.instance.manifest.path_for(css_entrypoint_name(path), **options)
  end

  private

  # we must add `styles/` because ViteRuby prepends assets folder to the request if `/` is missing
  # we must use `.css` extension, otherwise Vite will not detect this as a CSS entrypoint
  def css_entrypoint_name(path)
    "styles/#{path}.css"
  end
end
