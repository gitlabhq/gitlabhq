import FilterableList from '~/filterable_list';
import eventHub from './event_hub';

export default class GroupFilterableList extends FilterableList {
  constructor(form, filter, holder) {
    super(form, filter, holder);

    this.$dropdown = $('.js-group-filter-dropdown-wrap');
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

    this.filterResults();
  }

  onOptionClick(e) {
    e.preventDefault();
    const currentOption = $.trim(e.currentTarget.text);

    this.filterUrl = e.currentTarget.href;
    this.$dropdown.find('.dropdown-label').text(currentOption);
    this.filterResults(this.filterUrl);
  }

  preOnFilterSuccess(comingFrom) {
    if (comingFrom === 'filter-input') {
      this.filterUrl = `${this.filterForm.getAttribute('action')}?${$(this.filterForm).serialize()}`;
    }
  }

  onFilterSuccess(data, xhr) {
    super.onFilterSuccess(data);
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
