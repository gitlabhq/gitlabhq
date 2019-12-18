import $ from 'jquery';
import _ from 'underscore';
import axios from './lib/utils/axios_utils';

/**
 * Makes search request for content when user types a value in the search input.
 * Updates the html content of the page with the received one.
 */

export default class FilterableList {
  constructor(form, filter, holder, filterInputField = 'filter_groups') {
    this.filterForm = form;
    this.listFilterElement = filter;
    this.listHolderElement = holder;
    this.filterInputField = filterInputField;
    this.isBusy = false;
  }

  getFilterEndpoint() {
    return this.getPagePath();
  }

  getPagePath() {
    const action = this.filterForm.getAttribute('action');
    // eslint-disable-next-line no-jquery/no-serialize
    const params = $(this.filterForm).serialize();
    return `${action}${action.indexOf('?') > 0 ? '&' : '?'}${params}`;
  }

  initSearch() {
    // Wrap to prevent passing event arguments to .filterResults;
    this.debounceFilter = _.debounce(this.onFilterInput.bind(this), 500);

    this.unbindEvents();
    this.bindEvents();
  }

  onFilterInput() {
    const $form = $(this.filterForm);
    const queryData = {};
    const filterGroupsParam = $form.find(`[name="${this.filterInputField}"]`).val();

    if (filterGroupsParam) {
      queryData[this.filterInputField] = filterGroupsParam;
    }

    this.filterResults(queryData);

    if (this.setDefaultFilterOption) {
      this.setDefaultFilterOption();
    }
  }

  bindEvents() {
    this.listFilterElement.addEventListener('input', this.debounceFilter);
  }

  unbindEvents() {
    this.listFilterElement.removeEventListener('input', this.debounceFilter);
  }

  filterResults(params) {
    if (this.isBusy) {
      return false;
    }

    // eslint-disable-next-line no-jquery/no-fade
    $(this.listHolderElement).fadeTo(250, 0.5);

    this.isBusy = true;

    return axios
      .get(this.getFilterEndpoint(), {
        params,
      })
      .then(res => {
        this.onFilterSuccess(res, params);
        this.onFilterComplete();
      })
      .catch(() => this.onFilterComplete());
  }

  onFilterSuccess(response, queryData) {
    if (response.data.html) {
      this.listHolderElement.innerHTML = response.data.html;
    }

    // Change url so if user reload a page - search results are saved
    const currentPath = this.getPagePath(queryData);

    return window.history.replaceState(
      {
        page: currentPath,
      },
      document.title,
      currentPath,
    );
  }

  onFilterComplete() {
    this.isBusy = false;
    // eslint-disable-next-line no-jquery/no-fade
    $(this.listHolderElement).fadeTo(250, 1);
  }
}
