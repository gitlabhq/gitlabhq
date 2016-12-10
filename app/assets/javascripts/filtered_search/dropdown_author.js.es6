/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownAuthor extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-author';
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
          loadingTemplate: `
          <div class="filter-dropdown-loading">
            <i class="fa fa-spinner fa-spin"></i>
          </div>`,
        }
      };
    }

    itemClicked(e) {
      const username = e.detail.selected.querySelector('.dropdown-light-content').innerText.trim();
      gl.FilteredSearchManager.addWordToInput(this.getSelectedText(username));

      this.dismissDropdown();
    }

    renderContent(forceShowList) {
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabAjaxFilter], this.config);
      super.renderContent(forceShowList);
    }

    getSearchInput() {
      const query = document.querySelector('.filtered-search').value;
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1);
      const hasPrefix = valueWithoutColon[0] === '@';
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      if (hasPrefix) {
        return valueWithoutPrefix;
      } else {
        return valueWithoutColon;
      }
    }

    configure() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjaxFilter], this.config).init();
    }
  }

  global.DropdownAuthor = DropdownAuthor;
})(window.gl || (window.gl = {}));
