/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownMilestone extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-milestone';
      this.config = {
        droplabAjax: {
          endpoint: 'milestones.json',
          method: 'setData',
          loadingTemplate: this.loadingTemplate,
        },
        droplabFilter: {
          filterFunction: this.filterWithSymbol.bind(this, '%'),
        }
      };
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const milestoneTitle = e.detail.selected.querySelector('.btn-link').innerText.trim();
        const milestoneName = `%${this.getEscapedText(milestoneTitle)}`;
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(milestoneName));
      }

      this.dismissDropdown(!dataValueSet);
    }

    renderContent(forceShowList = false) {
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabAjax, droplabFilter], this.config);
      super.renderContent(forceShowList);
    }

    configure() {
      this.droplab.addHook(this.input, this.dropdown, [droplabAjax, droplabFilter], this.config).init();
    }
  }

  global.DropdownMilestone = DropdownMilestone;
})(window.gl || (window.gl = {}));
