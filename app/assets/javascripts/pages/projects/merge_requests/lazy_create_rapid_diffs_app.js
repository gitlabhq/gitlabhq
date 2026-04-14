import { getCookie } from '~/lib/utils/common_utils';
import { RAPID_DIFFS_COOKIE_NAME } from '~/rapid_diffs/constants';

function isRapidDiffsEnabled() {
  return (
    window.gon?.features?.rapidDiffsOnMrShow &&
    (new URLSearchParams(window.location.search).get('rapid_diffs') === 'true' ||
      getCookie(RAPID_DIFFS_COOKIE_NAME) === 'true')
  );
}

async function createRapidDiffsApp() {
  const { createMergeRequestRapidDiffsApp } = await import('~/rapid_diffs/merge_request_app');
  return createMergeRequestRapidDiffsApp();
}

export const lazyCreateRapidDiffsApp = isRapidDiffsEnabled() ? createRapidDiffsApp : null;
