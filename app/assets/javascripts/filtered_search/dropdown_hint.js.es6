/* eslint-disable no-param-reassign */
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

  class DropdownHint {
    constructor(dropdown, input) {
      this.input = input;
      this.dropdown = dropdown;
      this.bindEvents();
    }

    bindEvents() {
      this.dropdown.addEventListener('click.dl', this.itemClicked.bind(this));
    }

    unbindEvents() {
      this.dropdown.removeEventListener('click.dl', this.itemClicked.bind(this));
    }

    // cleanup() {
    //   this.unbindEvents();
    //   droplab.setConfig({'filtered-search': {}});
    //   droplab.setData('filtered-search', []);
    //   this.dropdown.style.display = 'hidden';
    // }

    getSelectedText(selectedToken) {
      // TODO: Get last word from FilteredSearchTokenizer
      const lastWord = this.input.value.split(' ').last();
      const lastWordIndex = selectedToken.indexOf(lastWord);

      return lastWordIndex === -1 ? selectedToken : selectedToken.slice(lastWord.length);
    }

    itemClicked(e) {
      const token = e.detail.selected.querySelector('.js-filter-hint').innerText.trim();
      const tag = e.detail.selected.querySelector('.js-filter-tag').innerText.trim();

      if (tag.length) {
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(token));
      }

      this.input.focus();
      this.dismissDropdown();

      // Propogate input change to FilteredSearchManager
      // so that it can determine which dropdowns to open
      this.input.dispatchEvent(new Event('input'));
    }

    dismissDropdown() {
      this.input.removeAttribute('data-dropdown-trigger');
      droplab.setConfig({'filtered-search': {}});
      droplab.setData('filtered-search', []);
      this.unbindEvents();
    }

    setAsDropdown() {
      this.input.setAttribute('data-dropdown-trigger', '#js-dropdown-hint');
      // const hookId = 'filtered-search';
      // const listId = 'js-dropdown-hint';
      // const hook = droplab.hooks.filter((h) => {
      //   return h.id === hookId;
      // })[0];

      // if (hook.list.list.id !== listId) {
      //   droplab.changeHookList(hookId, `#${listId}`);
      // }
    }

    render() {
      console.log('render dropdown hint');
      this.setAsDropdown();

      droplab.setConfig({
        'filtered-search': {
          text: 'hint'
        }
      });

      droplab.setData('filtered-search', dropdownData);
    }
  }

  global.DropdownHint = DropdownHint;
})(window.gl || (window.gl = {}));
