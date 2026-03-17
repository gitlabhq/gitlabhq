function isRapidDiffsEnabled() {
  return (
    window.gon?.features?.rapidDiffsOnMrShow &&
    new URLSearchParams(window.location.search).get('rapid_diffs') === 'true'
  );
}

async function createRapidDiffsApp() {
  const { createMergeRequestRapidDiffsApp } = await import('~/rapid_diffs/merge_request_app');
  return createMergeRequestRapidDiffsApp();
}

export const lazyCreateRapidDiffsApp = isRapidDiffsEnabled() ? createRapidDiffsApp : null;
