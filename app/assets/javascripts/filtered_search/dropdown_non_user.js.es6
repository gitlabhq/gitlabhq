/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownNonUser extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input, endpoint, symbol) {
      super(droplab, dropdown, input);
      this.listId = dropdown.id;
      this.config = {
        droplabAjax: {
          endpoint: endpoint,
          method: 'setData',
          loadingTemplate: this.loadingTemplate,
        },
        droplabFilter: {
          filterFunction: this.filterWithSymbol.bind(this, symbol),
        }
      };
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const title = e.detail.selected.querySelector('.js-data-value').innerText.trim();
        const name = `%${this.getEscapedText(title)}`;
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(name));
      }

      this.dismissDropdown(!dataValueSet);
    }

    renderContent(forceShowList = false) {
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabAjax, droplabFilter], this.config);
      super.renderContent(forceShowList);
    }

    configure() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjax, droplabFilter], this.config).init();
    }
  }

  global.DropdownNonUser = DropdownNonUser;
})(window.gl || (window.gl = {}));
