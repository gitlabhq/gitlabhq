/**
 * Makes search request for content when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */

export default class FilterableList {
  constructor(form, filter, holder, store) {
    this.store = store;
    this.filterForm = form;
    this.listFilterElement = filter;
    this.listHolderElement = holder;
  }

  initSearch() {
    this.debounceFilter = _.debounce(this.filterResults.bind(this), 500);

    this.listFilterElement.removeEventListener('input', this.debounceFilter);
    this.listFilterElement.addEventListener('input', this.debounceFilter);
  }

  filterResults() {
    const form = this.filterForm;
    const filterUrl = `${form.getAttribute('action')}?${$(form).serialize()}`;

    $(this.listHolderElement).fadeTo(250, 0.5);

    return $.ajax({
      url: form.getAttribute('action'),
      data: $(form).serialize(),
      type: 'GET',
      dataType: 'json',
      context: this,
      complete() {
        $(this.listHolderElement).fadeTo(250, 1);
      },
      success(data) {
        this.store.setGroups(data);

       // Change url so if user reload a page - search results are saved
        return window.history.replaceState({
          page: filterUrl,

        }, document.title, filterUrl);
      },
    });
  }
}
