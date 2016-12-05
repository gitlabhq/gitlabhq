/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownLabel extends gl.FilteredSearchDropdown {
    constructor(dropdown, input) {
      super(dropdown, input);
      this.listId = 'js-dropdown-label';
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const labelName = `~${e.detail.selected.querySelector('.label-title').innerText.trim()}`;
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(labelName));
      }

      this.dismissDropdown();
    }

    renderContent() {
      super.renderContent();
      droplab.setData(this.hookId, 'labels.json');
    }
  }

  global.DropdownLabel = DropdownLabel;
})(window.gl || (window.gl = {}));
