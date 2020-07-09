export default ({
  projectId,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
  releaseAssetsDocsPath,
  manageMilestonesPath,
  newMilestonePath,

  tagName = null,
  releasesPagePath = null,
  defaultBranch = null,
}) => ({
  projectId,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
  releaseAssetsDocsPath,
  manageMilestonesPath,
  newMilestonePath,

  tagName,
  releasesPagePath,
  defaultBranch,

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
