/**
 * Makes search request for content when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */

import './lib/utils/url_utility';

export default class FilterableList {
  constructor({ form, filter, holder, dropdownMenu }) {
    this.filterForm = form;
    this.listFilterElement = filter;
    this.listHolderElement = holder;
    this.dropdownMenu = dropdownMenu;
    if (dropdownMenu) {
      this.dropdownLabel = dropdownMenu.parentElement.querySelector('.dropdown-toggle-text');
    }
    this.isBusy = false;
  }

  getFilterEndpoint() {
    const url = this.filterForm.getAttribute('action');
    const params = this.getFormParams();
    return gl.utils.mergeUrlParams(params, url);
  }

  getFormParams() {
    return $(this.filterForm)
      .serializeArray()
      .filter(field => field.value !== '')
      .reduce((acc, field) => ({
        ...acc,
        [field.name]: field.value,
      }), {});
  }

  getPagePath() {
    return this.getFilterEndpoint();
  }

  initSearch() {
    // Wrap to prevent passing event arguments to .filterResults;
    this.debounceFilter = _.debounce(this.onFilterInput.bind(this), 500);
    this.updateButtonText = this.updateButtonText.bind(this);

    this.unbindEvents();
    this.bindEvents();
  }

  onFilterInput() {
    const $form = $(this.filterForm);
    const queryData = {};
    const filterGroupsParam = $form.find('[name="filter_groups"]').val();

    if (filterGroupsParam) {
      queryData.filter_groups = filterGroupsParam;
    }

    this.filterResults(queryData);

    if (this.setDefaultFilterOption) {
      this.setDefaultFilterOption();
    }
  }

  bindEvents() {
    this.listFilterElement.addEventListener('input', this.debounceFilter);

    if (this.dropdownMenu) {
      $(this.dropdownMenu).closest('form').on('change', this.debounceFilter);
      $(this.dropdownMenu).find('input[name="sort"]').on('change', this.updateButtonText);
    }
  }

  updateButtonText(evt) {
    this.dropdownLabel.innerText = evt.target.title;
  }

  unbindEvents() {
    this.listFilterElement.removeEventListener('input', this.debounceFilter);
    if (this.dropdownMenu) {
      $(this.dropdownMenu).closest('form').off('change', this.debounceFilter);
      $(this.dropdownMenu).find('input[name="sort"]').off('change', this.updateButtonText);
    }
  }

  filterResults(queryData) {
    if (this.isBusy) {
      return false;
    }

    $(this.listHolderElement).fadeTo(250, 0.5);

    return $.ajax({
      url: this.getFilterEndpoint(),
      data: queryData,
      type: 'GET',
      dataType: 'json',
      context: this,
      complete: this.onFilterComplete,
      beforeSend: () => {
        this.isBusy = true;
      },
      success: (response, textStatus, xhr) => {
        this.onFilterSuccess(response, xhr, queryData);
      },
    });
  }

  onFilterSuccess(response, xhr, queryData) {
    if (response.html) {
      this.listHolderElement.innerHTML = response.html;
    }

    // Change url so if user reload a page - search results are saved
    const currentPath = this.getPagePath(queryData);

    return window.history.replaceState({
      page: currentPath,
    }, document.title, currentPath);
  }

  onFilterComplete() {
    this.isBusy = false;
    $(this.listHolderElement).fadeTo(250, 1);
  }
}
