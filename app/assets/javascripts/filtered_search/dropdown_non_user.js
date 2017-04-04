require('./filtered_search_dropdown');

/* global droplabAjax */
/* global droplabFilter */

(() => {
  class DropdownNonUser extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input, filter, endpoint, symbol) {
      super(droplab, dropdown, input, filter);
      this.symbol = symbol;
      this.config = {
        droplabAjax: {
          endpoint,
          method: 'setData',
          loadingTemplate: this.loadingTemplate,
        },
        droplabFilter: {
          filterFunction: gl.DropdownUtils.filterWithSymbol.bind(null, this.symbol, input),
        },
      };
    }

    itemClicked(e) {
      super.itemClicked(e, (selected) => {
        const title = selected.querySelector('.js-data-value').innerText.trim();
        return `${this.symbol}${gl.DropdownUtils.getEscapedText(title)}`;
      });
    }

    renderContent(forceShowList = false) {
      this.droplab
        .changeHookList(this.hookId, this.dropdown, [droplabAjax, droplabFilter], this.config);
      super.renderContent(forceShowList);
    }

    init() {
      this.droplab
        .addHook(this.input, this.dropdown, [droplabAjax, droplabFilter], this.config).init();
    }
  }

  window.gl = window.gl || {};
  gl.DropdownNonUser = DropdownNonUser;
})();
