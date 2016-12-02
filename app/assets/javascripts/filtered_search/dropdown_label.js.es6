/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownLabel extends gl.FilteredSearchDropdown {
    constructor(dropdown, input) {
      super(dropdown, input);
      this.listId = 'js-dropdown-label';
    }

    itemClicked(e) {
      console.log('label clicked');
    }

    renderContent() {
      super.renderContent();
      droplab.setData(this.hookId, 'labels.json');
    }
  }

  global.DropdownLabel = DropdownLabel;
})(window.gl || (window.gl = {}));
