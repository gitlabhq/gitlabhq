/*= require filtered_search/filtered_search_dropdown */

/* global droplabFilter */

(() => {
  const dropdownData = [{
    icon: 'fa-pencil',
    hint: 'author:',
    tag: '&lt;author&gt;',
  }, {
    icon: 'fa-user',
    hint: 'assignee:',
    tag: '&lt;assignee&gt;',
  }, {
    icon: 'fa-clock-o',
    hint: 'milestone:',
    tag: '&lt;milestone&gt;',
  }, {
    icon: 'fa-tag',
    hint: 'label:',
    tag: '&lt;label&gt;',
  }];

  class DropdownHint extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.config = {
        droplabFilter: {
          template: 'hint',
          filterFunction: gl.DropdownUtils.filterMethod,
        },
      };
    }

    itemClicked(e) {
      const { selected } = e.detail;

      if (selected.hasAttribute('data-value')) {
        this.dismissDropdown();
      } else {
        const token = selected.querySelector('.js-filter-hint').innerText.trim();
        const tag = selected.querySelector('.js-filter-tag').innerText.trim();

        if (tag.length) {
          gl.FilteredSearchDropdownManager
            .addWordToInput(this.getSelectedTextWithoutEscaping(token));
        }
        this.dismissDropdown();
        this.dispatchInputEvent();
      }
    }

    getSelectedTextWithoutEscaping(selectedToken) {
      const lastWord = this.input.value.split(' ').last();
      const lastWordIndex = selectedToken.indexOf(lastWord);

      return lastWordIndex === -1 ? selectedToken : selectedToken.slice(lastWord.length);
    }

    renderContent() {
      this.droplab.changeHookList(this.hookId, this.dropdown, [droplabFilter], this.config);

      // Clone dropdownData to prevent it from being
      // changed due to pass by reference
      const data = [];
      dropdownData.forEach((item) => {
        data.push(Object.assign({}, item));
      });

      this.droplab.setData(this.hookId, data);
    }

    init() {
      this.droplab.addHook(this.input, this.dropdown, [droplabFilter], this.config).init();
    }
  }

  window.gl = window.gl || {};
  gl.DropdownHint = DropdownHint;
})();
