require 'webpack/rails/manifest'

module WebpackHelper
  def webpack_bundle_tag(bundle)
    javascript_include_tag(*gitlab_webpack_asset_paths(bundle))
  end

  # override webpack-rails gem helper until changes can make it upstream
  def gitlab_webpack_asset_paths(source, extension: nil)
    return "" unless source.present?

    paths = Webpack::Rails::Manifest.asset_paths(source)
    if extension
      paths.select! { |p| p.ends_with? ".#{extension}" }
    end

    force_host = webpack_public_host
    if force_host
      paths.map! { |p| "#{force_host}#{p}" }
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
    "#{webpack_public_host}/#{Rails.application.config.webpack.public_path}/"
  end
end
