/* global DropLab */

(() => {
  class FilteredSearchDropdownManager {
    constructor(baseEndpoint = '') {
      this.baseEndpoint = baseEndpoint.replace(/\/$/, '');
      this.tokenizer = gl.FilteredSearchTokenizer;
      this.filteredSearchInput = document.querySelector('.filtered-search');

      this.setupMapping();

      this.cleanupWrapper = this.cleanup.bind(this);
      document.addEventListener('page:fetch', this.cleanupWrapper);
    }

    cleanup() {
      if (this.droplab) {
        this.droplab.destroy();
        this.droplab = null;
      }

      this.setupMapping();

      document.removeEventListener('page:fetch', this.cleanupWrapper);
    }

    setupMapping() {
      this.mapping = {
        author: {
          reference: null,
          gl: 'DropdownUser',
          element: document.querySelector('#js-dropdown-author'),
        },
        assignee: {
          reference: null,
          gl: 'DropdownUser',
          element: document.querySelector('#js-dropdown-assignee'),
        },
        milestone: {
          reference: null,
          gl: 'DropdownNonUser',
          extraArguments: [`${this.baseEndpoint}/milestones.json`, '%'],
          element: document.querySelector('#js-dropdown-milestone'),
        },
        label: {
          reference: null,
          gl: 'DropdownNonUser',
          extraArguments: [`${this.baseEndpoint}/labels.json`, '~'],
          element: document.querySelector('#js-dropdown-label'),
        },
        hint: {
          reference: null,
          gl: 'DropdownHint',
          element: document.querySelector('#js-dropdown-hint'),
        },
      };
    }

    static addWordToInput(tokenName, tokenValue = '') {
      const input = document.querySelector('.filtered-search');
      const inputValue = input.value;
      const word = `${tokenName}:${tokenValue}`;

      // Get the string to replace
      let newCaretPosition = input.selectionStart;
      const { left, right } = gl.DropdownUtils.getInputSelectionPosition(input);

      input.value = `${inputValue.substr(0, left)}${word}${inputValue.substr(right)}`;

      // If we have added a tokenValue at the end of the input,
      // add a space and set selection to the end
      if (right >= inputValue.length && tokenValue !== '') {
        input.value += ' ';
        newCaretPosition = input.value.length;
      }

      gl.FilteredSearchDropdownManager.updateInputCaretPosition(newCaretPosition, input);
    }

    static updateInputCaretPosition(selectionStart, input) {
      // Reset the position
      // Sometimes can end up at end of input
      input.setSelectionRange(selectionStart, selectionStart);

      const { right } = gl.DropdownUtils.getInputSelectionPosition(input);

      input.setSelectionRange(right, right);
    }

    updateCurrentDropdownOffset() {
      this.updateDropdownOffset(this.currentDropdown);
    }

    updateDropdownOffset(key) {
      if (!this.font) {
        this.font = window.getComputedStyle(this.filteredSearchInput).font;
      }

      const input = this.filteredSearchInput;
      const inputText = input.value.slice(0, input.selectionStart);
      const filterIconPadding = 27;
      let offset = gl.text.getTextWidth(inputText, this.font) + filterIconPadding;

      const currentDropdownWidth = this.mapping[key].element.clientWidth === 0 ? 200 :
      this.mapping[key].element.clientWidth;
      const offsetMaxWidth = this.filteredSearchInput.clientWidth - currentDropdownWidth;

      if (offsetMaxWidth < offset) {
        offset = offsetMaxWidth;
      }

      this.mapping[key].reference.setOffset(offset);
    }

    load(key, firstLoad = false) {
      const mappingKey = this.mapping[key];
      const glClass = mappingKey.gl;
      const element = mappingKey.element;
      let forceShowList = false;

      if (!mappingKey.reference) {
        const dl = this.droplab;
        const defaultArguments = [null, dl, element, this.filteredSearchInput, key];
        const glArguments = defaultArguments.concat(mappingKey.extraArguments || []);

        // Passing glArguments to `new gl[glClass](<arguments>)`
        mappingKey.reference = new (Function.prototype.bind.apply(gl[glClass], glArguments))();
      }

      if (firstLoad) {
        mappingKey.reference.init();
      }

      if (this.currentDropdown === 'hint') {
        // Force the dropdown to show if it was clicked from the hint dropdown
        forceShowList = true;
      }

      this.updateDropdownOffset(key);
      mappingKey.reference.render(firstLoad, forceShowList);

      this.currentDropdown = key;
    }

    loadDropdown(dropdownName = '') {
      let firstLoad = false;

      if (!this.droplab) {
        firstLoad = true;
        this.droplab = new DropLab();
      }

      const match = gl.FilteredSearchTokenKeys.searchByKey(dropdownName.toLowerCase());
      const shouldOpenFilterDropdown = match && this.currentDropdown !== match.key
        && this.mapping[match.key];
      const shouldOpenHintDropdown = !match && this.currentDropdown !== 'hint';

      if (shouldOpenFilterDropdown || shouldOpenHintDropdown) {
        const key = match && match.key ? match.key : 'hint';
        this.load(key, firstLoad);
      }
    }

    setDropdown() {
      const { lastToken, searchToken } = this.tokenizer
        .processTokens(gl.DropdownUtils.getSearchInput(this.filteredSearchInput));

      if (this.currentDropdown) {
        this.updateCurrentDropdownOffset();
      }

      if (lastToken === searchToken && lastToken !== null) {
        // Token is not fully initialized yet because it has no value
        // Eg. token = 'label:'

        const split = lastToken.split(':');
        const dropdownName = split[0].split(' ').last();
        this.loadDropdown(split.length > 1 ? dropdownName : '');
      } else if (lastToken) {
        // Token has been initialized into an object because it has a value
        this.loadDropdown(lastToken.key);
      } else {
        this.loadDropdown('hint');
      }
    }

    resetDropdowns() {
      // Force current dropdown to hide
      this.mapping[this.currentDropdown].reference.hideDropdown();

      // Re-Load dropdown
      this.setDropdown();

      // Reset filters for current dropdown
      this.mapping[this.currentDropdown].reference.resetFilters();

      // Reposition dropdown so that it is aligned with cursor
      this.updateDropdownOffset(this.currentDropdown);
    }

    destroyDroplab() {
      this.droplab.destroy();
    }
  }

  window.gl = window.gl || {};
  gl.FilteredSearchDropdownManager = FilteredSearchDropdownManager;
})();
