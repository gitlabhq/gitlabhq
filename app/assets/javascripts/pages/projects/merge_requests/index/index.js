import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/shortcuts_navigation';
import UsersSelect from '~/users_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';

document.addEventListener('DOMContentLoaded', () => {
  FilteredSearchTokenKeys.addExtraTokensForMergeRequests();

  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    filteredSearchTokenKeys: FilteredSearchTokenKeys,
  });

  new IssuableIndex(ISSUABLE_INDEX.MERGE_REQUEST); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
