/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownMilestone extends gl.FilteredSearchDropdown {
    constructor(dropdown, input) {
      super(dropdown, input);
      this.listId = 'js-dropdown-milestone';
    }

    itemClicked(e) {
      console.log('milestone clicked');
    }

    renderContent() {
      super.renderContent();
      droplab.setData(this.hookId, 'milestones.json');
    }
  }

  global.DropdownMilestone = DropdownMilestone;
})(window.gl || (window.gl = {}));
