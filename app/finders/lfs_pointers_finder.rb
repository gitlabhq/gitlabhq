# frozen_string_literal: true

class LfsPointersFinder
  def initialize(repository, path)
    @repository = repository
    @path = path
  end

  def execute
    return [] unless ref

    blob_ids = tree.blobs.map(&:id)

    # When current endpoint is a Blob then `tree.blobs` will be empty, it means we need to analyze
    # the current Blob in order to determine if it's a LFS object
    blob_ids = Array.wrap(current_blob&.id) if blob_ids.empty?

    Gitlab::Git::Blob.batch_lfs_pointers(repository, blob_ids).map(&:id)
  end

  private

  attr_reader :repository, :path

  def ref
    repository.root_ref
  end

  def tree
    repository.tree(ref, path)
  end

  def current_blob
    repository.blob_at(ref, path)
  end
end
