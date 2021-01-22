import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import Project from '~/pages/projects/project';
import refreshCounts from '~/pages/search/show/refresh_counts';
import { queryToObject } from '~/lib/utils/url_utility';
import createStore from './store';
import { initTopbar } from './topbar';
import { initSidebar } from './sidebar';

export const initSearchApp = () => {
  // Similar to url_utility.decodeUrlParameter
  // Our query treats + as %20.  This replaces the query + symbols with %20.
  const sanitizedSearch = window.location.search.replace(/\+/g, '%20');
  const query = queryToObject(sanitizedSearch);

  const store = createStore({ query });

  initTopbar(store);
  initSidebar(store);

  setHighlightClass(query.search); // Code Highlighting
  refreshCounts(); // Other Scope Tab Counts
  Project.initRefSwitcher(); // Code Search Branch Picker
};
