import FilterableList from '~/filterable_list';
import eventHub from './event_hub';

export default class GroupFilterableList extends FilterableList {
  constructor({ form, filter, holder, filterEndpoint, pagePath }) {
    super(form, filter, holder);
    this.form = form;
    this.filterEndpoint = filterEndpoint;
    this.pagePath = pagePath;
    this.$dropdown = $('.js-group-filter-dropdown-wrap');
  }

  getFilterEndpoint() {
    return this.filterEndpoint;
  }

  getPagePath(queryData) {
    const params = queryData ? $.param(queryData) : '';
    const queryString = params ? `?${params}` : '';
    return `${this.pagePath}${queryString}`;
  }

  bindEvents() {
    super.bindEvents();

    this.onFormSubmitWrapper = this.onFormSubmit.bind(this);
    this.onFilterOptionClikWrapper = this.onOptionClick.bind(this);

    this.filterForm.addEventListener('submit', this.onFormSubmitWrapper);
    this.$dropdown.on('click', 'a', this.onFilterOptionClikWrapper);
  }

  onFormSubmit(e) {
    e.preventDefault();

    const $form = $(this.form);
    const filterGroupsParam = $form.find('[name="filter_groups"]').val();
    const queryData = {};

    if (filterGroupsParam) {
      queryData.filter_groups = filterGroupsParam;
    }

    this.filterResults(queryData);
    this.setDefaultFilterOption();
  }

  setDefaultFilterOption() {
    const defaultOption = $.trim(this.$dropdown.find('.dropdown-menu a:first-child').text());
    this.$dropdown.find('.dropdown-label').text(defaultOption);
  }

  onOptionClick(e) {
    e.preventDefault();

    const queryData = {};
    const sortParam = gl.utils.getParameterByName('sort', e.currentTarget.href);

    if (sortParam) {
      queryData.sort = sortParam;
    }

    this.filterResults(queryData);

    // Active selected option
    this.$dropdown.find('.dropdown-label').text($.trim(e.currentTarget.text));

    // Clear current value on search form
    this.form.querySelector('[name="filter_groups"]').value = '';
  }

  onFilterSuccess(data, xhr, queryData) {
    super.onFilterSuccess(data, xhr, queryData);

    const paginationData = {
      'X-Per-Page': xhr.getResponseHeader('X-Per-Page'),
      'X-Page': xhr.getResponseHeader('X-Page'),
      'X-Total': xhr.getResponseHeader('X-Total'),
      'X-Total-Pages': xhr.getResponseHeader('X-Total-Pages'),
      'X-Next-Page': xhr.getResponseHeader('X-Next-Page'),
      'X-Prev-Page': xhr.getResponseHeader('X-Prev-Page'),
    };

    eventHub.$emit('updateGroups', data);
    eventHub.$emit('updatePagination', paginationData);
  }
}
