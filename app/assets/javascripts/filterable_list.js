/**
 * Makes search request for content when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */

export default class FilterableList {
  constructor(form, filter, holder) {
    this.filterForm = form;
    this.listFilterElement = filter;
    this.listHolderElement = holder;
    this.filterUrl = `${this.filterForm.getAttribute('action')}?${$(this.filterForm).serialize()}`;
  }

  initSearch() {
    this.debounceFilter = _.debounce(this.filterResults.bind(this), 500);

    this.unbindEvents();
    this.bindEvents();
  }

  bindEvents() {
    this.listFilterElement.addEventListener('input', this.debounceFilter);
  }

  unbindEvents() {
    this.listFilterElement.removeEventListener('input', this.debounceFilter);
  }

  filterResults() {

    $(this.listHolderElement).fadeTo(250, 0.5);

    return $.ajax({
      url: this.filterForm.getAttribute('action'),
      data: $(this.filterForm).serialize(),
      type: 'GET',
      dataType: 'json',
      context: this,
      complete: this.onFilterComplete,
      success: this.onFilterSuccess,
    });
  }

  onFilterSuccess(data) {
   // Change url so if user reload a page - search results are saved
    return window.history.replaceState({
      page: this.filterUrl,

    }, document.title, this.filterUrl);
  }

  onFilterComplete() {
    $(this.listHolderElement).fadeTo(250, 1);
  }
}
