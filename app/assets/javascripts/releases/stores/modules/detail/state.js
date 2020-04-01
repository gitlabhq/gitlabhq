export default ({
  projectId,
  tagName,
  releasesPagePath,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
  releaseAssetsDocsPath,
}) => ({
  projectId,
  tagName,
  releasesPagePath,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
  releaseAssetsDocsPath,

  /** The Release object */
  release: null,

  /**
   * A deep clone of the Release object above.
   * Used when editing this Release so that
   * changes can be computed.
   */
  originalRelease: null,

  isFetchingRelease: false,
  fetchError: null,

  isUpdatingRelease: false,
  updateError: null,
});
