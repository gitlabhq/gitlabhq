import AdminRunnersFilteredSearchTokenKeys from '~/filtered_search/admin_runners_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { initInstallRunner } from '~/pages/shared/mount_runner_instructions';
import { initAdminRunners } from '~/runner/admin_runners';

initFilteredSearch({
  page: FILTERED_SEARCH.ADMIN_RUNNERS,
  filteredSearchTokenKeys: AdminRunnersFilteredSearchTokenKeys,
  useDefaultState: true,
});

initInstallRunner();

if (gon.features?.runnerListViewVueUi) {
  initAdminRunners();
}
