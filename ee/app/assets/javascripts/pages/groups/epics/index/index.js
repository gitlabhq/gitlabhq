import initFilteredSearch from '~/pages/search/init_filtered_search';
import FilteredSearchTokenKeysEpics from 'ee/filtered_search/filtered_search_token_keys_epics';
import initNewEpic from 'ee/epics/new_epic/new_epic_bundle';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: 'epics',
    isGroup: true,
    isGroupDecendent: true,
    filteredSearchTokenKeys: FilteredSearchTokenKeysEpics,
    stateFiltersSelector: '.epics-state-filters',
  });
  initNewEpic();
});
