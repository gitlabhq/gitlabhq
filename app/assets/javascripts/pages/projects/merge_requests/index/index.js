import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import UsersSelect from '~/users_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';

document.addEventListener('DOMContentLoaded', () => {
  addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);

  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });

  new IssuableIndex(ISSUABLE_INDEX.MERGE_REQUEST); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
