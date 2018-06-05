# This is a wrapper for Blob model.
# It acts as a thin layer which caches lightweight information
# based on the blob content (which is not cached).
class BlobsService
  def initialize(project, content_sha, path)
    @project = project
    @content_sha = content_sha
    @path = path
  end

  def id
    blob.id
  end

  def raw_size
    blob.raw_size
  end

  def size
    blob.size
  end

  def readable_text?
    blob.readable_text?
  end

  def name
    blob.name
  end

  def total_lines
    blob.total_lines
  end

  def binary?
    blob.binary?
  end

  def path
    blob.path
  end

  def external_storage_error?
    blob.external_storage_error?
  end

  def stored_externally?
    blob.stored_externally?
  end

  def raw_binary?
    blob.raw_binary?
  end

  def load_all_data!
    blob.load_all_data!
  end

  def data
    blob.data
  end

  def clear_cache
    cache.delete(cache_key)
  end

  private

  def blob
    if cache_exists?
      # TODO: This can be a CachedBlob
      Hashie::Mash.new(read_cache)
    else
      write_cache
      blob
    end
  end

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

  def write_cache
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

  def cache_key
    [@project.id, @content_sha, @path]
  end
end
