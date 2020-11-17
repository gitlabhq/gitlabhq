import { queryToObject } from '~/lib/utils/url_utility';
import createStore from './store';
import { initSidebar } from './sidebar';
import initGroupFilter from './group_filter';

export const initSearchApp = () => {
  // Similar to url_utility.decodeUrlParameter
  // Our query treats + as %20.  This replaces the query + symbols with %20.
  const sanitizedSearch = window.location.search.replace(/\+/g, '%20');
  const store = createStore({ query: queryToObject(sanitizedSearch) });

  initSidebar(store);
  initGroupFilter(store);
};
