import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import { queryToObject } from '~/lib/utils/url_utility';
import Project from '~/pages/projects/project';
import refreshCounts from '~/pages/search/show/refresh_counts';
import { initSidebar } from './sidebar';
import { initSearchSort } from './sort';
import createStore from './store';
import { initTopbar } from './topbar';

export const initSearchApp = () => {
  const query = queryToObject(window.location.search);

  const store = createStore({ query });

  initTopbar(store);
  initSidebar(store);
  initSearchSort(store);

  setHighlightClass(query.search); // Code Highlighting
  refreshCounts(); // Other Scope Tab Counts
  Project.initRefSwitcher(); // Code Search Branch Picker
};
