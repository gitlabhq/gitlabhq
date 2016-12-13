/*= require filtered_search/filtered_search_dropdown */
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
          filterFunction: this.filterMethod,
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
      this.droplab.setData(this.hookId, dropdownData);
    }

    filterMethod(item, query) {
      const updatedItem = item;
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);

      if (value === '') {
        updatedItem.droplab_hidden = false;
      } else {
        updatedItem.droplab_hidden = updatedItem.hint.indexOf(value) === -1;
      }

      return updatedItem;
    }

    init() {
      this.droplab.addHook(this.input, this.dropdown, [droplabFilter], this.config).init();
    }
  }

  window.gl = window.gl || {};
  gl.DropdownHint = DropdownHint;
})();
