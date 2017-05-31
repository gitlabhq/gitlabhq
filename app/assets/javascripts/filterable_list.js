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
    // Wrap to prevent passing event arguments to .filterResults;
    this.debounceFilter = _.debounce(this.onFilterInput.bind(this), 500);

    this.unbindEvents();
    this.bindEvents();
  }

  onFilterInput() {
    const url = this.filterForm.getAttribute('action');
    const data = $(this.filterForm).serialize();
    this.filterResults(url, data, 'filter-input');
  }

  bindEvents() {
    this.listFilterElement.addEventListener('input', this.debounceFilter);
  }

  unbindEvents() {
    this.listFilterElement.removeEventListener('input', this.debounceFilter);
  }

  filterResults(url, data, comingFrom) {
    const endpoint = url || this.filterForm.getAttribute('action');
    const additionalData = data || $(this.filterForm).serialize();

    $(this.listHolderElement).fadeTo(250, 0.5);

    return $.ajax({
      url: endpoint,
      data: additionalData,
      type: 'GET',
      dataType: 'json',
      context: this,
      complete: this.onFilterComplete,
      success: (response, textStatus, xhr) => {
        if (this.preOnFilterSuccess) {
          this.preOnFilterSuccess(comingFrom);
        }

        this.onFilterSuccess(response, xhr);
      },
    });
  }

  onFilterSuccess(data) {
    if (data.html) {
      this.listHolderElement.innerHTML = data.html;
    }

   // Change url so if user reload a page - search results are saved
    return window.history.replaceState({
      page: this.filterUrl,

    }, document.title, this.filterUrl);
  }

  onFilterComplete() {
    $(this.listHolderElement).fadeTo(250, 1);
  }
}
