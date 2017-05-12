import FilterableList from '~/filterable_list';

export default class GroupFilterableList extends FilterableList {
  constructor(form, filter, holder, store) {
    super(form, filter, holder);

    this.store = store;
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

  onFilterSuccess(data) {
    super.onFilterSuccess(data);

    this.store.setGroups(data);
  }
}
