/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownLabel extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-label';
      this.filterSymbol = '~';
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const labelTitle = e.detail.selected.querySelector('.label-title').innerText.trim();
        const labelName = `~${this.getEscapedText(labelTitle)}`;
        gl.FilteredSearchManager.addWordToInput(labelName);
      }

      this.dismissDropdown();
    }

    renderContent() {
      // TODO: Pass elements instead of querySelectors
      // TODO: Don't bind filterWithSymbol to (this), just pass the symbol
      this.droplab.changeHookList(this.hookId, '#js-dropdown-label', [droplabAjax, droplabFilter], {
        droplabAjax: {
          endpoint: 'labels.json',
          method: 'setData',
        },
        droplabFilter: {
          filterFunction: this.filterWithSymbol.bind(this),
        }
      });
    }
  }

  global.DropdownLabel = DropdownLabel;
})(window.gl || (window.gl = {}));
