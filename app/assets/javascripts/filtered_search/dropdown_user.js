/* global Flash */

import AjaxFilter from '~/droplab/plugins/ajax_filter';

require('./filtered_search_dropdown');

class DropdownUser extends gl.FilteredSearchDropdown {
  constructor(droplab, dropdown, input, tokenKeys, filter) {
    super(droplab, dropdown, input, filter);
    this.config = {
      AjaxFilter: {
        endpoint: `${gon.relative_url_root || ''}/autocomplete/users.json`,
        searchKey: 'search',
        params: {
          per_page: 20,
          active: true,
          project_id: this.getProjectId(),
          current_user: true,
        },
        searchValueFunction: this.getSearchInput.bind(this),
        loadingTemplate: this.loadingTemplate,
        onError() {
          /* eslint-disable no-new */
          new Flash('An error occured fetching the dropdown data.');
          /* eslint-enable no-new */
        },
      },
    };
    this.tokenKeys = tokenKeys;
  }

  itemClicked(e) {
    super.itemClicked(e,
      selected => selected.querySelector('.dropdown-light-content').innerText.trim());
  }

  renderContent(forceShowList = false) {
    this.droplab.changeHookList(this.hookId, this.dropdown, [AjaxFilter], this.config);
    super.renderContent(forceShowList);
  }

  getProjectId() {
    return this.input.getAttribute('data-project-id');
  }

  getSearchInput() {
    const query = gl.DropdownUtils.getSearchInput(this.input);
    const { lastToken } = gl.FilteredSearchTokenizer.processTokens(query, this.tokenKeys.get());

    let value = lastToken || '';

    if (value[0] === '@') {
      value = value.slice(1);
    }

    // Removes the first character if it is a quotation so that we can search
    // with multiple words
    if (value[0] === '"' || value[0] === '\'') {
      value = value.slice(1);
    }

    return value;
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [AjaxFilter], this.config).init();
  }
}

window.gl = window.gl || {};
gl.DropdownUser = DropdownUser;
