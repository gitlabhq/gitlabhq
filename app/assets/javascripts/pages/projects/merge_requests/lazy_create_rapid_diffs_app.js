async function createRapidDiffsApp() {
  const { createMergeRequestRapidDiffsApp } =
    await import('ee_else_ce/rapid_diffs/merge_request_app');
  return createMergeRequestRapidDiffsApp();
}

export const lazyCreateRapidDiffsApp = window.gon?.rapid_diffs_page_enabled
  ? createRapidDiffsApp
  : null;
