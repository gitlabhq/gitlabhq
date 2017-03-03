import FilterableList from './filterable_list';

/**
 * Makes search request for projects when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */
export default class ProjectsList {
  constructor() {
    var form = document.querySelector('form#project-filter-form');
    var filter = document.querySelector('.js-projects-list-filter');
    var holder = document.querySelector('.js-projects-list-holder');

    new FilterableList(form, filter, holder);
  }
}
