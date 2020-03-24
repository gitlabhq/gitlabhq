export default ({
  projectId,
  tagName,
  releasesPagePath,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
}) => ({
  projectId,
  tagName,
  releasesPagePath,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,

  release: null,

  isFetchingRelease: false,
  fetchError: null,

  isUpdatingRelease: false,
  updateError: null,
});
