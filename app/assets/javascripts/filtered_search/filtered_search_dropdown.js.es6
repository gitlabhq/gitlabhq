/* eslint-disable no-param-reassign */
((global) => {
  const DATA_DROPDOWN_TRIGGER = 'data-dropdown-trigger';

  class FilteredSearchDropdown {
    constructor(dropdown, input) {
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
      const filterConfig = {
        text: filterKeyword,
      };

      config[this.hookId] = filterKeyword ? filterConfig : {};

      return config;
    }

    dismissDropdown() {
      this.input.setAttribute(DATA_DROPDOWN_TRIGGER, '');
      droplab.setConfig(this.getFilterConfig());
      droplab.setData(this.hookId, []);
      this.unbindEvents();
    }

    setAsDropdown() {
      this.input.setAttribute(DATA_DROPDOWN_TRIGGER, `#${this.listId}`);
    }

    setOffset(offset = 0) {
      this.dropdown.style.left = `${offset}px`;
    }

    getCurrentHook() {
      return droplab.hooks.filter(h => h.id === this.hookId)[0];
    }

    renderContent() {
      droplab.setConfig(this.getFilterConfig(this.filterKeyword));
    }

    render() {
      this.setAsDropdown();

      const firstTimeInitialized = this.getCurrentHook() === undefined;

      if (firstTimeInitialized) {
        this.renderContent();
      } else if(this.getCurrentHook().list.list.id !== this.listId) {
        droplab.changeHookList(this.hookId, `#${this.listId}`);
        this.renderContent();
      }
    }
  }

  global.FilteredSearchDropdown = FilteredSearchDropdown;
})(window.gl || (window.gl = {}));
