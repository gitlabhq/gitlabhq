/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownNonUser extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input, endpoint, symbol) {
      super(droplab, dropdown, input);
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
      super.itemClicked(e, (selected) => {
        const title = e.detail.selected.querySelector('.js-data-value').innerText.trim();
        return `${this.symbol}${this.getEscapedText(title)}`;
      });
    }

    getEscapedText(text) {
      let escapedText = text;
      const hasSpace = text.indexOf(' ') !== -1;
      const hasDoubleQuote = text.indexOf('"') !== -1;

      // Encapsulate value with quotes if it has spaces
      // Known side effect: values's with both single and double quotes
      // won't escape properly
      if (hasSpace) {
        if (hasDoubleQuote) {
          escapedText = `'${text}'`;
        } else {
          // Encapsulate singleQuotes or if it hasSpace
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

    init() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjax, droplabFilter], this.config).init();
    }
  }

  global.DropdownNonUser = DropdownNonUser;
})(window.gl || (window.gl = {}));
