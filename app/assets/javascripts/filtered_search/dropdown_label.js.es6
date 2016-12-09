/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownLabel extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-label';
      this.config = {
        droplabAjax: {
          endpoint: 'labels.json',
          method: 'setData',
        },
        droplabFilter: {
          filterFunction: this.filterWithSymbol.bind(this, '~'),
        }
      };
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
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabAjax, droplabFilter], this.config);
    }

    configure() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjax, droplabFilter], this.config).init();
    }
  }

  global.DropdownLabel = DropdownLabel;
})(window.gl || (window.gl = {}));
