import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/shortcuts_navigation';
import UsersSelect from '~/users_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
<<<<<<< HEAD
import IssuesFilteredSearchTokenKeys from '~/filtered_search/issues_filtered_search_token_keys';
=======
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
>>>>>>> upstream/master
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
<<<<<<< HEAD
    filteredSearchTokenKeys: IssuesFilteredSearchTokenKeys,
=======
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
>>>>>>> upstream/master
  });
  new IssuableIndex(ISSUABLE_INDEX.MERGE_REQUEST); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
