/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownMilestone extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-milestone';
      this.filterSymbol = '%';
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const milestoneTitle = e.detail.selected.querySelector('.btn-link').innerText.trim();
        const milestoneName = `%${this.getEscapedText(milestoneTitle)}`;
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(milestoneName));
      }

      this.dismissDropdown();
    }

    renderContent() {
      // TODO: Pass elements instead of querySelectors
      this.droplab.changeHookList(this.hookId, '#js-dropdown-milestone', [droplabAjax, droplabFilter], {
        droplabAjax: {
          endpoint: 'milestones.json',
          method: 'setData',
        },
        droplabFilter: {
          filterFunction: this.filterWithSymbol.bind(this),
        }
      });
    }
  }

  global.DropdownMilestone = DropdownMilestone;
})(window.gl || (window.gl = {}));
