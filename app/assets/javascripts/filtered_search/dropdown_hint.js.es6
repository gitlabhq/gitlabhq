/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  const dropdownData = [{
    icon: 'fa-search',
    hint: 'Keep typing and press Enter',
    tag: '',
  },{
    icon: 'fa-pencil',
    hint: 'author:',
    tag: '&lt;author&gt;'
  },{
    icon: 'fa-user',
    hint: 'assignee:',
    tag: '&lt;assignee&gt;',
  },{
    icon: 'fa-clock-o',
    hint: 'milestone:',
    tag: '&lt;milestone&gt;',
  },{
    icon: 'fa-tag',
    hint: 'label:',
    tag: '&lt;label&gt;',
  }];

  class DropdownHint extends gl.FilteredSearchDropdown {
    constructor(dropdown, input, filterKeyword) {
      super(dropdown, input);
      this.listId = 'js-dropdown-hint';
      this.filterKeyword = filterKeyword;
    }

    itemClicked(e) {
      const token = e.detail.selected.querySelector('.dropdown-filter-hint').innerText.trim();
      const tag = e.detail.selected.querySelector('.dropdown-filter-tag').innerText.trim();

      if (tag.length) {
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(token));
      }

      this.input.focus();
      this.dismissDropdown();

      // Propogate input change to FilteredSearchManager
      // so that it can determine which dropdowns to open
      this.input.dispatchEvent(new Event('input'));
    }

    renderContent() {
      super.renderContent();
      droplab.setData(this.hookId, dropdownData);
    }
  }

  global.DropdownHint = DropdownHint;
})(window.gl || (window.gl = {}));
