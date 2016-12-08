/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  const dropdownData = [{
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
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-hint';
    }

    itemClicked(e) {
      const token = e.detail.selected.querySelector('.js-filter-hint').innerText.trim();
      const tag = e.detail.selected.querySelector('.js-filter-tag').innerText.trim();

      if (tag.length) {
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(token));
      }

      this.dismissDropdown();
    }

    renderContent() {
      this.droplab.changeHookList(this.hookId, '#js-dropdown-hint', [droplabFilter], {
        droplabFilter: {
          template: 'hint',
          filterFunction: this.filterMethod,
        }
      });
      this.droplab.setData(this.hookId, dropdownData);
    }

    filterMethod(item, query) {
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);

      if (value === '') {
        item.droplab_hidden = false;
      } else {
        item.droplab_hidden = item['hint'].indexOf(value) === -1;
      }

      return item;
    }

    configure() {
      this.droplab.addHook(this.input, this.dropdown, [droplabFilter], {
        droplabFilter: {
          template: 'hint',
        }
      }).init();
    }
  }

  global.DropdownHint = DropdownHint;
})(window.gl || (window.gl = {}));
