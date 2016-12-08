/* eslint-disable no-param-reassign */
((global) => {
  const DATA_DROPDOWN_TRIGGER = 'data-dropdown-trigger';

  class FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      this.droplab = droplab;
      this.hookId = 'filtered-search';
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

    getFilterConfig(filterKeyword) {
      const config = {};
      const filterConfig = {};

      if (filterKeyword) {
        filterConfig.text = filterKeyword;
      }

      if (this.filterMethod) {
        filterConfig.filter = this.filterMethod;
      }

      config[this.hookId] = filterConfig;
      return config;
    }

    destroy() {
      this.input.setAttribute(DATA_DROPDOWN_TRIGGER, '');
      this.droplab.setConfig(this.getFilterConfig());
      this.droplab.setData(this.hookId, []);
      this.unbindEvents();
    }

    dismissDropdown() {
      this.input.focus();
      // Propogate input change to FilteredSearchManager
      // so that it can determine which dropdowns to open
      this.input.dispatchEvent(new Event('input'));
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

    getCurrentHook() {
      return this.droplab.hooks.filter(h => h.id === this.hookId)[0];
    }

    renderContent() {
      // Overriden by dropdown sub class
    }

    render(forceRenderContent) {
      this.setAsDropdown();

      const firstTimeInitialized = this.getCurrentHook() === undefined;

      if (firstTimeInitialized || forceRenderContent) {
        this.renderContent();
      } else if(this.getCurrentHook().list.list.id !== this.listId) {
        // this.droplab.changeHookList(this.hookId, `#${this.listId}`);
        this.renderContent();
      }
    }

    resetFilters() {
      const currentHook = this.getCurrentHook();

      if (currentHook) {
        const list = currentHook.list;

        if (list.data) {
          const data = list.data.map((item) => {
            item.droplab_hidden = false;
          });

          list.render(data);
        }
      }
    }

    hide() {
      const currentHook = this.getCurrentHook();
      if (currentHook) {
        currentHook.list.hide();
      }
    }

    filterWithSymbol(item, query) {
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1).toLowerCase();
      const prefix = valueWithoutColon[0];
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      const title = item.title.toLowerCase();

      // Eg. this.filterSymbol = ~ for labels
      const matchWithoutPrefix = prefix === this.filterSymbol && title.indexOf(valueWithoutPrefix) !== -1;
      const match = title.indexOf(valueWithoutColon) !== -1;

      item.droplab_hidden = !match && !matchWithoutPrefix;
      return item;
    }
  }

  global.FilteredSearchDropdown = FilteredSearchDropdown;
})(window.gl || (window.gl = {}));
