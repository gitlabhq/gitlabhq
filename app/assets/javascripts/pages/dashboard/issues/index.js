import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { mountIssuesDashboardApp } from '~/issues/dashboard';
import initManualOrdering from '~/issues/manual_ordering';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import projectSelect from '~/project_select';
import { initNewResourceDropdown } from '~/vue_shared/components/new_resource_dropdown/init_new_resource_dropdown';

initFilteredSearch({
  page: FILTERED_SEARCH.ISSUES,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

projectSelect();
initNewResourceDropdown();
initManualOrdering();

mountIssuesDashboardApp();
