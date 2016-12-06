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
        let labelTitle = e.detail.selected.querySelector('.label-title').innerText.trim();

        // Encapsulate label with quotes if it has spaces
        if (labelTitle.indexOf(' ') !== -1) {
          if (labelTitle.indexOf('"') !== -1) {
            // Use single quotes if label title contains double quotes
            labelTitle = `'${labelTitle}'`;
          } else {
            // Known side effect: Label's with both single and double quotes
            // won't escape properly
            labelTitle = `"${labelTitle}"`;
          }
        }

        const labelName = `~${labelTitle}`;
        gl.FilteredSearchManager.addWordToInput(labelName);
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
