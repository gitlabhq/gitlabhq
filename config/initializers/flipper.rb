require 'flipper/adapters/active_record'
require 'flipper/adapters/active_support_cache_store'

Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new(
      feature_class: Feature::FlipperFeature, gate_class: Feature::FlipperGate)
    cached_adapter = Flipper::Adapters::ActiveSupportCacheStore.new(
      adapter,
      Rails.cache,
      expires_in: 1.hour)

    Flipper.new(cached_adapter)
  end
end

Feature.register_feature_groups

unless Rails.env.test?
  require 'flipper/middleware/memoizer'
  Rails.application.config.middleware.use Flipper::Middleware::Memoizer
end
