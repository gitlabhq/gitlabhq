import initSettingsPanels from '~/settings_panels';
import initVariableList from '~/ci_variable_list';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import GroupRunnersFilteredSearchTokenKeys from '~/filtered_search/group_runners_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import initSharedRunnersForm from '~/group_settings/mount_shared_runners';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();

  initFilteredSearch({
    page: FILTERED_SEARCH.ADMIN_RUNNERS,
    filteredSearchTokenKeys: GroupRunnersFilteredSearchTokenKeys,
    anchor: FILTERED_SEARCH.GROUP_RUNNERS_ANCHOR,
    useDefaultState: false,
  });

  initSharedRunnersForm();
  initVariableList();
});
