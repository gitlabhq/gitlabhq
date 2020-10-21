import { queryToObject } from '~/lib/utils/url_utility';
import createStore from './store';
import initDropdownFilters from './dropdown_filter';

export default () => {
  const store = createStore({ query: queryToObject(window.location.search) });

  initDropdownFilters(store);
};
