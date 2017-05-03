/*= require filtered_search/filtered_search_dropdown */

/* global droplabAjaxFilter */

(() => {
  class DropdownUser extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input, filter) {
      super(droplab, dropdown, input, filter);
      this.config = {
        droplabAjaxFilter: {
          endpoint: '/autocomplete/users.json',
          searchKey: 'search',
          params: {
            per_page: 20,
            active: true,
            project_id: this.getProjectId(),
            current_user: true,
          },
          searchValueFunction: this.getSearchInput.bind(this),
          loadingTemplate: this.loadingTemplate,
        },
      };
    }

    itemClicked(e) {
      super.itemClicked(e,
        selected => selected.querySelector('.dropdown-light-content').innerText.trim());
    }

    renderContent(forceShowList = false) {
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabAjaxFilter], this.config);
      super.renderContent(forceShowList);
    }

    getProjectId() {
      return this.input.getAttribute('data-project-id');
    }

    getSearchInput() {
      const query = gl.DropdownUtils.getSearchInput(this.input);
      const { lastToken } = gl.FilteredSearchTokenizer.processTokens(query);

      return lastToken.value || '';
    }

    init() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjaxFilter], this.config).init();
    }
  }

  window.gl = window.gl || {};
  gl.DropdownUser = DropdownUser;
})();
