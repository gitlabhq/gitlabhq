# frozen_string_literal: true

module LocalCacheRegistryCleanupWithEnsure
  LocalCacheRegistry =
    ActiveSupport::Cache::Strategy::LocalCache::LocalCacheRegistry
  LocalStore =
    ActiveSupport::Cache::Strategy::LocalCache::LocalStore

  def call(env)
    LocalCacheRegistry.set_cache_for(local_cache_key, LocalStore.new)
    response = @app.call(env) # rubocop:disable Gitlab/ModuleWithInstanceVariables
    response[2] = ::Rack::BodyProxy.new(response[2]) do
      LocalCacheRegistry.set_cache_for(local_cache_key, nil)
    end
    cleanup_after_response = true # ADDED THIS LINE
    response
  rescue Rack::Utils::InvalidParameterError
    [400, {}, []]
  ensure # ADDED ensure CLAUSE to cleanup when something is thrown
    LocalCacheRegistry.set_cache_for(local_cache_key, nil) unless
      cleanup_after_response
  end
end

ActiveSupport::Cache::Strategy::LocalCache::Middleware
  .prepend(LocalCacheRegistryCleanupWithEnsure)
