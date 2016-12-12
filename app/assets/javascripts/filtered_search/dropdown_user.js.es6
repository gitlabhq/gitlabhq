/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownUser extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = dropdown.id;
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
          searchValueFunction: this.getSearchInput,
          loadingTemplate: this.loadingTemplate,
        },
      };
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const username = e.detail.selected.querySelector('.dropdown-light-content').innerText.trim();
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(username));
      }

      this.dismissDropdown(!dataValueSet);
    }

    renderContent(forceShowList = false) {
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabAjaxFilter], this.config);
      super.renderContent(forceShowList);
    }

    getProjectId() {
      return this.input.getAttribute('data-project-id');
    }

    getSearchInput() {
      const query = document.querySelector('.filtered-search').value;
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1);
      const hasPrefix = valueWithoutColon[0] === '@';
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      return hasPrefix ? valueWithoutPrefix : valueWithoutColon;
    }

    configure() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjaxFilter], this.config).init();
    }
  }

  global.DropdownUser = DropdownUser;
})(window.gl || (window.gl = {}));
