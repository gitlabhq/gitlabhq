# This worker clears all cache fields in the database, working in batches.
class ClearDatabaseCacheWorker
  include Sidekiq::Worker

  BATCH_SIZE = 1000

  def perform
    CacheMarkdownField.caching_classes.each do |kls|
      fields = kls.cached_markdown_fields.html_fields
      clear_cache_fields = fields.each_with_object({}) do |field, memo|
        memo[field] = nil
      end

      Rails.logger.debug("Clearing Markdown cache for #{kls}: #{fields.inspect}")

      kls.unscoped.in_batches(of: BATCH_SIZE) do |relation|
        relation.update_all(clear_cache_fields)
      end
    end

    nil
  end
end
