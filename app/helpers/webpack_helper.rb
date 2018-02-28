require 'webpack/rails/manifest'

module WebpackHelper
  def webpack_bundle_tag(bundle, force_same_domain: false)
    javascript_include_tag(*gitlab_webpack_asset_paths(bundle, force_same_domain: force_same_domain))
  end

  # override webpack-rails gem helper until changes can make it upstream
  def gitlab_webpack_asset_paths(source, extension: nil, force_same_domain: false)
    return "" unless source.present?

    paths = Webpack::Rails::Manifest.asset_paths(source)
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
