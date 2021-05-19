# frozen_string_literal: true

module WebpackHelper
  def prefetch_link_tag(source)
    href = asset_path(source)

    link_tag = tag.link(rel: 'prefetch', href: href)

    early_hints_link = "<#{href}>; rel=prefetch"

    request.send_early_hints("Link" => early_hints_link)

    link_tag
  end

  def webpack_bundle_tag(bundle)
    javascript_include_tag(*webpack_entrypoint_paths(bundle))
  end

  def webpack_preload_asset_tag(asset, options = {})
    path = Gitlab::Webpack::Manifest.asset_paths(asset).first

    if options.delete(:prefetch)
      prefetch_link_tag(path)
    else
      preload_link_tag(path, options)
    end
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

    if chunks.empty?
      chunks = webpack_entrypoint_paths("default", extension: 'js')
    end

    javascript_include_tag(*chunks)
  end

  def webpack_entrypoint_paths(source, extension: nil, exclude_duplicates: true)
    return "" unless source.present?

    paths = Gitlab::Webpack::Manifest.entrypoint_paths(source)
    if extension
      paths.select! { |p| p.ends_with? ".#{extension}" }
    end

    force_host = webpack_public_host
    if force_host
      paths.map! { |p| "#{force_host}#{p}" }
    end

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
    # We do not proxy the webpack output in the 'test' environment,
    # so we must reference the webpack dev server directly.
    if Rails.env.test? && Gitlab.config.webpack.dev_server.enabled
      host = Gitlab.config.webpack.dev_server.host
      port = Gitlab.config.webpack.dev_server.port
      protocol = Gitlab.config.webpack.dev_server.https ? 'https' : 'http'
      "#{protocol}://#{host}:#{port}"
    else
      ActionController::Base.asset_host.try(:chomp, '/')
    end
  end

  def webpack_public_path
    relative_path = Gitlab.config.gitlab.relative_url_root
    webpack_path = Gitlab.config.webpack.public_path
    File.join(webpack_public_host.to_s, relative_path.to_s, webpack_path.to_s, '')
  end
end
