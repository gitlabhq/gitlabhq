import FilterableList from './filterable_list';

/**
 * Makes search request for groups when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */
export default class GroupsList {
  constructor() {
    var form = document.querySelector('form#group-filter-form');
    var filter = document.querySelector('.js-groups-list-filter');
    var holder = document.querySelector('.js-groups-list-holder');

    new FilterableList(form, filter, holder);
  }
}
