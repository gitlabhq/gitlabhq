import { queryToObject } from '~/lib/utils/url_utility';
import createStore from './store';
import { initSidebar } from './sidebar';
import initGroupFilter from './group_filter';

export default () => {
  const store = createStore({ query: queryToObject(window.location.search) });

  initSidebar(store);
  initGroupFilter(store);
};
