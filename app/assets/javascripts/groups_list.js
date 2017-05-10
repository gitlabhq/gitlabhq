import FilterableList from './filterable_list';

/**
 * Makes search request for groups when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */
export default class GroupsList {
  constructor(form, filter, holder, store) {
    if (form && filter && holder && store) {
      const list = new FilterableList(form, filter, holder, store);
      list.initSearch();
    }
  }
}
