import initFilteredSearch from '~/pages/search/init_filtered_search';
import AdminRunnersFilteredSearchTokenKeys from '~/filtered_search/admin_runners_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import { initInstallRunner } from '~/pages/shared/mount_runner_instructions';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ADMIN_RUNNERS,
    filteredSearchTokenKeys: AdminRunnersFilteredSearchTokenKeys,
    useDefaultState: true,
  });

  if (gon?.features?.runnerInstructions) {
    initInstallRunner();
  }
});
