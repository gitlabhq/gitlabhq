import FilterableList from './filterable_list';

/**
 * Makes search request for groups when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */
export default class GroupsList {
  constructor() {
    const form = document.querySelector('form#group-filter-form');
    const filter = document.querySelector('.js-groups-list-filter');
    const holder = document.querySelector('.js-groups-list-holder');

    if (form && filter && holder) {
      const list = new FilterableList(form, filter, holder);
      list.initSearch();
    }
  }
}
