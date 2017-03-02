/**
 * Based on project list search.
 * Makes search request for groups when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */
export default class GroupsList {
  constructor() {
    this.groupsListFilterElement = document.querySelector('.js-groups-list-filter');
    this.groupsListHolderElement = document.querySelector('.js-groups-list-holder');

    this.initSearch();
  }

  initSearch() {
    this.debounceFilter = _.debounce(this.filterResults.bind(this), 500);

    this.groupsListFilterElement.removeEventListener('input', this.debounceFilter);
    this.groupsListFilterElement.addEventListener('input', this.debounceFilter);
  }

  filterResults() {
    const form = document.querySelector('form#group-filter-form');
    const groupFilterUrl = `${form.getAttribute('action')}?${$(form).serialize()}`;

    $(this.groupsListHolderElement).fadeTo(250, 0.5);

    return $.ajax({
      url: form.getAttribute('action'),
      data: $(form).serialize(),
      type: 'GET',
      dataType: 'json',
      context: this,
      complete() {
        $(this.groupsListHolderElement).fadeTo(250, 1);
      },
      success(data) {
        this.groupsListHolderElement.innerHTML = data.html;

       // Change url so if user reload a page - search results are saved
        return window.history.replaceState({
          page: groupFilterUrl,

        }, document.title, groupFilterUrl);
      },
    });
  }
}
