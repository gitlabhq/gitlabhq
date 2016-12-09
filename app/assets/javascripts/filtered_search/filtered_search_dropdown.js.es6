/* eslint-disable no-param-reassign */
((global) => {
  const DATA_DROPDOWN_TRIGGER = 'data-dropdown-trigger';

  class FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      console.log('constructor');
      this.droplab = droplab;
      this.hookId = 'filtered-search';
      this.input = input;
      this.dropdown = dropdown;
      this.bindEvents();
    }

    bindEvents() {
      this.itemClickedWrapper = this.itemClicked.bind(this);
      this.dropdown.addEventListener('click.dl', this.itemClickedWrapper);
    }

    unbindEvents() {
      this.dropdown.removeEventListener('click.dl', this.itemClickedWrapper);
    }

    getCurrentHook() {
      return this.droplab.hooks.filter(h => h.id === this.hookId)[0];
    }

    getEscapedText(text) {
      let escapedText = text;

      // Encapsulate value with quotes if it has spaces
      if (text.indexOf(' ') !== -1) {
        if (text.indexOf('"') !== -1) {
          // Use single quotes if value contains double quotes
          escapedText = `'${text}'`;
        } else {
          // Known side effect: values's with both single and double quotes
          // won't escape properly
          escapedText = `"${text}"`;
        }
      }

      return escapedText;
    }

    getSelectedText(selectedToken) {
      // TODO: Get last word from FilteredSearchTokenizer
      const lastWord = this.input.value.split(' ').last();
      const lastWordIndex = selectedToken.indexOf(lastWord);

      return lastWordIndex === -1 ? selectedToken : selectedToken.slice(lastWord.length);
    }

    itemClicked(e) {
      // Overridden by dropdown sub class
    }

    renderContent(forceShowList = false) {
      if (forceShowList && this.getCurrentHook().list.hidden) {
        this.getCurrentHook().list.show();
      }
    }

    setAsDropdown() {
      this.input.setAttribute(DATA_DROPDOWN_TRIGGER, `#${this.listId}`);
    }

    setOffset(offset = 0) {
      this.dropdown.style.left = `${offset}px`;
    }

    setDataValueIfSelected(selected) {
      const dataValue = selected.getAttribute('data-value');

      if (dataValue) {
        gl.FilteredSearchManager.addWordToInput(dataValue);
      }

      return dataValue !== null;
    }

    dismissDropdown() {
      this.input.focus();
    }

    dispatchInputEvent() {
      // Propogate input change to FilteredSearchManager
      // so that it can determine which dropdowns to open
      this.input.dispatchEvent(new Event('input'));
    }

    render(forceRenderContent = false, forceShowList = false) {
      this.setAsDropdown();

      const currentHook = this.getCurrentHook();
      const firstTimeInitialized = currentHook === undefined;

      if (firstTimeInitialized || forceRenderContent) {
        this.renderContent(forceShowList);
      } else if(currentHook.list.list.id !== this.listId) {
        this.renderContent(forceShowList);
      }
    }

    filterWithSymbol(filterSymbol, item, query) {
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1).toLowerCase();
      const prefix = valueWithoutColon[0];
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      const title = item.title.toLowerCase();

      // Eg. filterSymbol = ~ for labels
      const matchWithoutPrefix = prefix === filterSymbol && title.indexOf(valueWithoutPrefix) !== -1;
      const match = title.indexOf(valueWithoutColon) !== -1;

      item.droplab_hidden = !match && !matchWithoutPrefix;
      return item;
    }

    hideDropdown() {
      this.getCurrentHook().list.hide();
    }

    resetFilters() {
      const hook = this.getCurrentHook();
      const data = hook.list.data;
      const results = data.map(function(o) {
        o.droplab_hidden = false;
      });
      hook.list.render(results);
    }
  }

  global.FilteredSearchDropdown = FilteredSearchDropdown;
})(window.gl || (window.gl = {}));
