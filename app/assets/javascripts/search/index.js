import { queryToObject } from '~/lib/utils/url_utility';
import createStore from './store';
import initDropdownFilters from './dropdown_filter';
import { initSidebar } from './sidebar';
import initGroupFilter from './group_filter';

export default () => {
  const store = createStore({ query: queryToObject(window.location.search) });

  if (gon.features.searchFacets) {
    initSidebar(store);
  } else {
    initDropdownFilters(store);
  }

  initGroupFilter(store);
};
