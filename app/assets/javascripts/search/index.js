import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import { queryToObject } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import syntaxHighlight from '~/syntax_highlight';
import { initSidebar } from './sidebar';
import { initSearchSort } from './sort';
import createStore from './store';
import { initTopbar } from './topbar';
import { initBlobRefSwitcher } from './under_topbar';
import { SEARCH_TYPE_ZOEKT, SCOPE_BLOB } from './sidebar/constants/index';
import { initZoektBlobResult } from './results/index';

const sidebarInitState = () => {
  const el = document.getElementById('js-search-sidebar');
  if (!el) return {};

  const {
    navigationJson,
    searchType,
    searchLevel,
    advancedSearchAvailable,
    zoektAvailable,
    groupInitialJson,
    projectInitialJson,
    ref,
  } = el.dataset;

  const navigationJsonParsed = JSON.parse(navigationJson);
  const groupInitialJsonParsed = JSON.parse(groupInitialJson);
  const projectInitialJsonParsed = JSON.parse(projectInitialJson);

  return {
    navigationJsonParsed,
    searchType,
    searchLevel,
    advancedSearchAvailable: parseBoolean(advancedSearchAvailable),
    zoektAvailable: parseBoolean(zoektAvailable),
    groupInitialJsonParsed,
    projectInitialJsonParsed,
    ref,
  };
};

const topBarInitState = () => {
  const el = document.getElementById('js-search-topbar');

  if (!el) {
    return false;
  }

  const { defaultBranchName } = el.dataset;
  return { defaultBranchName };
};

export const initSearchApp = () => {
  syntaxHighlight(document.querySelectorAll('.js-search-results'));
  const query = queryToObject(window.location.search, { gatherArrays: true });
  const {
    navigationJsonParsed: navigation,
    searchType,
    searchLevel,
    advancedSearchAvailable,
    zoektAvailable,
    groupInitialJsonParsed: groupInitialJson,
    projectInitialJsonParsed: projectInitialJson,
    ref,
  } = sidebarInitState() || {};

  const { defaultBranchName } = topBarInitState() || {};

  const store = createStore({
    query,
    navigation,
    searchType,
    searchLevel,
    advancedSearchAvailable,
    zoektAvailable,
    groupInitialJson,
    projectInitialJson,
    defaultBranchName,
    repositoryRef: ref,
  });

  initTopbar(store);
  initSidebar(store);
  initSearchSort(store);

  setHighlightClass(query.search); // Code Highlighting
  initBlobRefSwitcher(); // Code Search Branch Picker

  if (
    searchType === SEARCH_TYPE_ZOEKT &&
    store.getters.currentScope === SCOPE_BLOB &&
    gon.features.zoektMultimatchFrontend
  ) {
    initZoektBlobResult(store);
  }
};
