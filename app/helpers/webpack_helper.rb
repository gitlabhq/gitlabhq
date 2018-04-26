require 'gitlab/webpack/manifest'

module WebpackHelper
  def webpack_bundle_tag(bundle, force_same_domain: false)
    javascript_include_tag(*entrypoint_paths(bundle, force_same_domain: force_same_domain))
  end

  def webpack_controller_bundle_tags
    bundles = []

    action = case controller.action_name
             when 'create' then 'new'
             when 'update' then 'edit'
             else controller.action_name
             end

    route = [*controller.controller_path.split('/'), action].compact

    until route.empty?
      begin
        asset_paths = entrypoint_paths("pages.#{route.join('.')}", extension: 'js')
        bundles.unshift(*asset_paths)
      rescue Gitlab::Webpack::Manifest::AssetMissingError
        # no bundle exists for this path
      end

      route.pop
    end

    javascript_include_tag(*bundles.uniq)
  end

  def entrypoint_paths(source, extension: nil, force_same_domain: false)
    return "" unless source.present?

    paths = Gitlab::Webpack::Manifest.entrypoint_paths(source)
    if extension
      paths.select! { |p| p.ends_with? ".#{extension}" }
    end

    unless force_same_domain
      force_host = webpack_public_host
      if force_host
        paths.map! { |p| "#{force_host}#{p}" }
      end
    end

    paths
  end

  def webpack_public_host
    if Rails.env.test? && Rails.configuration.webpack.dev_server.enabled
      host = Rails.configuration.webpack.dev_server.host
      port = Rails.configuration.webpack.dev_server.port
      protocol = Rails.configuration.webpack.dev_server.https ? 'https' : 'http'
      "#{protocol}://#{host}:#{port}"
    else
      ActionController::Base.asset_host.try(:chomp, '/')
    end
  end

  def webpack_public_path
    relative_path = Rails.application.config.relative_url_root
    webpack_path = Rails.application.config.webpack.public_path
    File.join(webpack_public_host.to_s, relative_path.to_s, webpack_path.to_s, '')
  end
end
