require 'webpack/rails/manifest'

module WebpackHelper
  def webpack_bundle_tag(bundle, opts = {})
    javascript_include_tag(*gitlab_webpack_asset_paths(bundle), opts)
  end

  # override webpack-rails gem helper until changes can make it upstream
  def gitlab_webpack_asset_paths(source, extension: nil)
    return "" unless source.present?

    paths = Webpack::Rails::Manifest.asset_paths(source)
    if extension
      paths = paths.select { |p| p.ends_with? ".#{extension}" }
    end

    # include full webpack-dev-server url for rspec tests running locally
    if Rails.env.test? && Rails.configuration.webpack.dev_server.enabled
      host = Rails.configuration.webpack.dev_server.host
      port = Rails.configuration.webpack.dev_server.port
      protocol = Rails.configuration.webpack.dev_server.https ? 'https' : 'http'

      paths.map! do |p|
        "#{protocol}://#{host}:#{port}#{p}"
      end
    end

    paths
  end
end
