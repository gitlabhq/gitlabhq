import Search from './search';
import initStateFilter from '~/search/state_filter';

document.addEventListener('DOMContentLoaded', () => {
  initStateFilter();
  return new Search();
});
