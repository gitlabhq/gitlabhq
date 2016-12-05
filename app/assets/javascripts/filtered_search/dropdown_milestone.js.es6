/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownMilestone extends gl.FilteredSearchDropdown {
    constructor(dropdown, input) {
      super(dropdown, input);
      this.listId = 'js-dropdown-milestone';
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        console.log('set value');
      }

      this.dismissDropdown();
    }

    renderContent() {
      super.renderContent();
      droplab.setData(this.hookId, 'milestones.json');
    }
  }

  global.DropdownMilestone = DropdownMilestone;
})(window.gl || (window.gl = {}));
