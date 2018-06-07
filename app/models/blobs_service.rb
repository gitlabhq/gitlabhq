# This is a wrapper for Blob model.
# It acts as a thin layer which caches lightweight information
# based on the blob content (which is not cached).
class BlobsService
  def initialize(project, content_sha, path)
    @project = project
    @content_sha = content_sha
    @path = path
  end

  def write_cache_if_empty
    return unless content_sha
    return if cache_exists?
    return unless uncached_blob

    blob_cache = { id: uncached_blob.id,
                   raw_size: uncached_blob.raw_size,
                   size: uncached_blob.size,
                   readable_text: uncached_blob.readable_text?,
                   name: uncached_blob.name,
                   binary: uncached_blob.binary?,
                   path: uncached_blob.path,
                   external_storage_error: uncached_blob.external_storage_error?,
                   stored_externally: uncached_blob.stored_externally?,
                   total_lines: uncached_blob.total_lines }

    cache.write(cache_key, blob_cache, expires_in: 1.week)
  end

  def clear_cache
    cache.delete(cache_key)
  end

  # We need blobs data (content) in order to highlight diffs (see
  # Gitlab::Diff:Highlight), and we don't cache this (Blob#data) on Redis,
  # mainly because it's a quite heavy information to cache for every blob.
  #
  # Therefore, in this scenario (no highlight yet) we use the uncached blob
  # version.
  def blob(highlighted:)
    return unless content_sha
    return uncached_blob unless highlighted

    if cache_exists?
      # TODO: This can be a CachedBlob
      Hashie::Mash.new(read_cache)
    else
      uncached_blob
    end
  end

  private

  attr_reader :content_sha

  def uncached_blob
    @uncached_blob ||= Blob.lazy(@project, @content_sha, @path)&.itself
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
    [@project.id, @content_sha, @path]
  end
end
