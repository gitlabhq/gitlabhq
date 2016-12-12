/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownNonUser extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input, endpoint, symbol) {
      super(droplab, dropdown, input);
      this.listId = dropdown.id;
      this.symbol = symbol;
      this.config = {
        droplabAjax: {
          endpoint: endpoint,
          method: 'setData',
          loadingTemplate: this.loadingTemplate,
        },
        droplabFilter: {
          filterFunction: this.filterWithSymbol.bind(this, this.symbol),
        }
      };
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const title = e.detail.selected.querySelector('.js-data-value').innerText.trim();
        const name = `${this.symbol}${this.getEscapedText(title)}`;
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(name));
      }

      this.dismissDropdown(!dataValueSet);
    }

    getEscapedText(text) {
      let escapedText = text;

      // Encapsulate value with quotes if it has spaces
      if (text.indexOf(' ') !== -1) {
        if (text.indexOf('"') !== -1) {
          // Use single quotes if value contains double quotes
          escapedText = `'${text}'`;
        } else {
          // Known side effect: values's with both single and double quotes
          // won't escape properly
          escapedText = `"${text}"`;
        }
      }

      return escapedText;
    }

    filterWithSymbol(filterSymbol, item, query) {
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1).toLowerCase();
      const prefix = valueWithoutColon[0];
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      const title = item.title.toLowerCase();

      // Eg. filterSymbol = ~ for labels
      const matchWithoutPrefix = prefix === filterSymbol && title.indexOf(valueWithoutPrefix) !== -1;
      const match = title.indexOf(valueWithoutColon) !== -1;

      item.droplab_hidden = !match && !matchWithoutPrefix;
      return item;
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
