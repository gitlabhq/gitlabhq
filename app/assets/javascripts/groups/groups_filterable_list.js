import FilterableList from '~/filterable_list';


export default class GroupFilterableList extends FilterableList {
  constructor(form, filter, holder, store) {
    super(form, filter, holder);

    this.store = store;
  }

  bindEvents() {
    super.bindEvents();

    this.onFormSubmitWrapper = this.onFormSubmit.bind(this);
    this.filterForm.addEventListener('submit', this.onFormSubmitWrapper);
  }

  onFormSubmit(e) {
    e.preventDefault();

    this.filterResults();
  }

  onFilterSuccess(data) {
    super.onFilterSuccess();

    this.store.setGroups(data);
  }
}
