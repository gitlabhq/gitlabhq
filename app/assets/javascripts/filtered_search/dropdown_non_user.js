/* global Flash */

import Ajax from '~/droplab/plugins/ajax';
import Filter from '~/droplab/plugins/filter';
import './filtered_search_dropdown';

class DropdownNonUser extends gl.FilteredSearchDropdown {
  constructor(options = {}) {
    const { input, endpoint, symbol } = options;
    super(options);
    this.symbol = symbol;
    this.config = {
      Ajax: {
        endpoint,
        method: 'setData',
        loadingTemplate: this.loadingTemplate,
        onError() {
          /* eslint-disable no-new */
          new Flash('An error occured fetching the dropdown data.');
          /* eslint-enable no-new */
        },
      },
      Filter: {
        filterFunction: gl.DropdownUtils.filterWithSymbol.bind(null, this.symbol, input),
        template: 'title',
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
      .changeHookList(this.hookId, this.dropdown, [Ajax, Filter], this.config);
    super.renderContent(forceShowList);
  }

  init() {
    this.droplab
      .addHook(this.input, this.dropdown, [Ajax, Filter], this.config).init();
  }
}

window.gl = window.gl || {};
gl.DropdownNonUser = DropdownNonUser;
