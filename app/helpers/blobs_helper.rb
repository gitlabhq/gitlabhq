module BlobsHelper
  def find_blob(repository, sha, path)
    Gitlab::Git::Blob.find(repository, sha, path)
  end
end
