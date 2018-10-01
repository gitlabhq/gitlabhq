import FilteredSearchDropdown from './filtered_search_dropdown';

export default class NullDropdown extends FilteredSearchDropdown {
  renderContent(forceShowList = false) {
    this.droplab.changeHookList(this.hookId, this.dropdown, [], this.config);

    super.renderContent(forceShowList);
  }
}
