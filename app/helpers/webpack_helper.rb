# frozen_string_literal: true

module WebpackHelper
  include ViteHelper

  def prefetch_link_tag(source)
    href = asset_path(source)

    link_tag = tag.link(rel: 'prefetch', href: href)

    early_hints_link = "<#{href}>; rel=prefetch"

    request.send_early_hints("Link" => early_hints_link)

    link_tag
  end

  def webpack_bundle_tag(bundle)
    if vite_enabled?
      vite_javascript_tag bundle
    else
      javascript_include_tag(*webpack_entrypoint_paths(bundle))
    end
  end

  def webpack_preload_asset_tag(asset, options = {})
    return if vite_enabled?

    path = Gitlab::Webpack::Manifest.asset_paths(asset).first

    if options.delete(:prefetch)
      prefetch_link_tag(path)
    else
      preload_link_tag(path, options)
    end
  rescue Gitlab::Webpack::Manifest::AssetMissingError
    # In development/test, incremental compilation may be enabled, meaning not
    # all chunks may be available/split out
    raise unless Gitlab.dev_or_test_env?
  end

  def webpack_controller_bundle_tags
    chunks = []

    action = case controller.action_name
             when 'create' then 'new'
             when 'update' then 'edit'
             else controller.action_name
             end

    route = [*controller.controller_path.split('/'), action].compact

    until chunks.any? || route.empty?
      entrypoint = "pages.#{route.join('.')}"
      begin
        chunks = webpack_entrypoint_paths(entrypoint, extension: 'js')
      rescue Gitlab::Webpack::Manifest::AssetMissingError
        # no bundle exists for this path
      end
      route.pop
    end

    chunks = webpack_entrypoint_paths("default", extension: 'js') if chunks.empty?

    javascript_include_tag(*chunks)
  end

  def webpack_entrypoint_paths(source, extension: nil, exclude_duplicates: true)
    return "" unless source.present?

    paths = Gitlab::Webpack::Manifest.entrypoint_paths(source)
    paths.select! { |p| p.ends_with? ".#{extension}" } if extension

    force_host = webpack_public_host
    paths.map! { |p| "#{force_host}#{p}" } if force_host

    if exclude_duplicates
      @used_paths ||= []
      new_paths = paths - @used_paths
      @used_paths += new_paths
      new_paths
    else
      paths
    end
  end

  def webpack_public_host
    # We proxy webpack output in 'test' and 'dev' environment, so we can just use asset_host
    ActionController::Base.asset_host.try(:chomp, '/')
  end

  def webpack_public_path
    relative_path = Gitlab.config.gitlab.relative_url_root
    webpack_path = Gitlab.config.webpack.public_path
    File.join(webpack_public_host.to_s, relative_path.to_s, webpack_path.to_s, '')
  end
end
