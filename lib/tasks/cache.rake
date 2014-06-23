namespace :cache do
  desc "GITLAB | Clear redis cache"
  task :clear => :environment do
    # Hack into Rails.cache until https://github.com/redis-store/redis-store/pull/225
    # is accepted (I hope) and we can update the redis-store gem.
    redis_store = Rails.cache.instance_variable_get(:@data)
    redis_store.keys.each_slice(1000) do |key_slice|
      redis_store.del(*key_slice)
    end
  end
end
