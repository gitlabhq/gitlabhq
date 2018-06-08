# This is a thin caching wrapper class for Blob model.
# It acts as a thin layer which caches lightweight information
# based on the blob content (which is not cached).
class BlobsService
  CACHED_METHODS = %i(id raw_size size readable_text? name raw_binary? binary? path
                      external_storage_error? stored_externally? total_lines).freeze

  def initialize(project, content_sha, path)
    @project = project
    @content_sha = content_sha
    @path = path
  end

  def lazy_load_uncached_blob
    return unless content_sha
    return if cache_exists?

    uncached_blob
  end

  # We need blobs data (content) in order to highlight diffs (see
  # Gitlab::Diff:Highlight), and we don't cache this (Blob#data) on Redis,
  # mainly because it's a quite heavy information to cache for every blob.
  #
  # Therefore, in this scenario (no highlight yet) we use the uncached blob
  # version.
  def fetch(highlighted:)
    return unless content_sha
    return uncached_blob unless highlighted

    cache_exists? ? cached_blob : uncached_blob&.itself
  end


  def write_cache_if_empty
    return unless content_sha
    return if cache_exists?
    return unless uncached_blob

    cache.write(cache_key, cacheable_blob_hash, expires_in: 1.week)
  end

  def clear_cache
    cache.delete(cache_key)
  end

  private

  attr_reader :content_sha, :project, :path

  def cacheable_blob_hash
    CACHED_METHODS.each_with_object({}) do |_method, hash|
      hash[_method] = uncached_blob.public_send(_method)
    end
  end

  def cached_blob
    CachedBlob.new(read_cache)
  end

  def uncached_blob
    Blob.lazy(project, content_sha, path)
  end

  def cache
    @cache ||= Rails.cache
  end

  def read_cache
    cache.read(cache_key)
  end

  def cache_exists?
    cache.exist?(cache_key)
  end

  def cache_key
    [project.id, content_sha, path]
  end
end
