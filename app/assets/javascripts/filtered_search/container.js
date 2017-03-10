let _container = document;

class FilteredSearchContainerClass {
  set container(container) {
    _container = container;
  }

  get container() {
    return _container;
  }
}

export let FilteredSearchContainer = new FilteredSearchContainerClass();
