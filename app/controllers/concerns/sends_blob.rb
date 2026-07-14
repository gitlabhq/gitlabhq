# frozen_string_literal: true

module SendsBlob
  extend ActiveSupport::Concern

  included do
    include BlobHelper
    include SendFileUpload
  end

  def send_blob(repository, blob, inline: true, allow_caching: false, force_revalidate: false)
    if blob
      headers['X-Content-Type-Options'] = 'nosniff'

      return if cached_blob?(blob, allow_caching: allow_caching, force_revalidate: force_revalidate)

      if blob.stored_externally?
        send_lfs_object(blob, repository.project)
      else
        send_git_blob(repository, blob, inline: inline)
      end
    else
      render_404
    end
  end

  private

  def cached_blob?(blob, allow_caching: false, force_revalidate: false)
    stale = stale?(strong_etag: blob.id)

    max_age, options = blob_cache_directives(allow_caching: allow_caching, force_revalidate: force_revalidate)
    # Because we are opinionated we set the cache headers ourselves.
    expires_in(max_age, **options)

    !stale
  end

  # When force_revalidate is set, the caller mutates this blob's content under
  # a stable URL (e.g. a snippet served at a branch ref). Every cache window
  # must be zero so the browser and any shared cache (CDN) revalidate via the
  # ETag on every request rather than serving the pre-save copy via max-age,
  # s-maxage, stale-while-revalidate, or stale-if-error.
  def blob_cache_directives(allow_caching:, force_revalidate:)
    if force_revalidate
      return [0, { public: allow_caching, must_revalidate: true,
                   stale_if_error: 0, stale_while_revalidate: 0, 's-maxage': 0 }]
    end

    max_age =
      if @ref && @commit && @ref == @commit.id # rubocop:disable Gitlab/ModuleWithInstanceVariables
        # This is a link to a commit by its commit SHA. That means that the blob
        # is immutable. The only reason to invalidate the cache is if the commit
        # was deleted or if the user lost access to the repository.
        Blob::CACHE_TIME_IMMUTABLE
      else
        # A branch or tag points at this blob. That means that the expected blob
        # value may change over time.
        Blob::CACHE_TIME
      end

    [max_age, { public: allow_caching, must_revalidate: true,
                stale_if_error: 5.minutes, stale_while_revalidate: 1.minute, 's-maxage': 1.minute }]
  end

  def send_lfs_object(blob, project)
    lfs_object = find_lfs_object(blob)

    if lfs_object && lfs_object.project_allowed_access?(project)
      send_upload(lfs_object.file, attachment: blob.name)
    else
      render_404
    end
  end

  def find_lfs_object(blob)
    lfs_object = LfsObject.find_by_oid(blob.lfs_oid)
    if lfs_object && lfs_object.file.exists?
      lfs_object
    else
      nil
    end
  end
end
