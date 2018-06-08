class CachedBlob
  delegate *BlobsService::CACHED_METHODS, to: :@blob_cache

  def initialize(blob_cache)
    @blob_cache = OpenStruct.new(blob_cache)
  end

  def load_all_data!
    # no-op
  end
end
