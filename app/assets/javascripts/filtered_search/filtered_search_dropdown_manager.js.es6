(() => {
  class FilteredSearchDropdownManager {
    constructor() {
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
          extraArguments: ['milestones.json', '%'],
          element: document.querySelector('#js-dropdown-milestone'),
        },
        label: {
          reference: null,
          gl: 'DropdownNonUser',
          extraArguments: ['labels.json', '~'],
          element: document.querySelector('#js-dropdown-label'),
        },
        hint: {
          reference: null,
          gl: 'DropdownHint',
          element: document.querySelector('#js-dropdown-hint'),
        },
      };
    }

    static addWordToInput(word, addSpace = false) {
      const input = document.querySelector('.filtered-search');
      const value = input.value;
      const hasExistingValue = value.length !== 0;
      const { lastToken } = gl.FilteredSearchTokenizer.processTokens(value);

      if ({}.hasOwnProperty.call(lastToken, 'key')) {
        // Spaces inside the token means that the token value will be escaped by quotes
        const hasQuotes = lastToken.value.indexOf(' ') !== -1;

        // Add 2 length to account for the length of the front and back quotes
        const lengthToRemove = hasQuotes ? lastToken.value.length + 2 : lastToken.value.length;
        input.value = value.slice(0, -1 * (lengthToRemove));
      }

      input.value += hasExistingValue && addSpace ? ` ${word}` : word;
    }

    updateCurrentDropdownOffset() {
      this.updateDropdownOffset(this.currentDropdown);
    }

    updateDropdownOffset(key) {
      if (!this.font) {
        this.font = window.getComputedStyle(this.filteredSearchInput).font;
      }

      const filterIconPadding = 27;
      const offset = gl.text
        .getTextWidth(this.filteredSearchInput.value, this.font) + filterIconPadding;

      this.mapping[key].reference.setOffset(offset);
    }

    load(key, firstLoad = false) {
      const mappingKey = this.mapping[key];
      const glClass = mappingKey.gl;
      const element = mappingKey.element;
      let forceShowList = false;

      if (!mappingKey.reference) {
        const dl = this.droplab;
        const defaultArguments = [null, dl, element, this.filteredSearchInput];
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
        && {}.hasOwnProperty.call(this.mapping, match.key);
      const shouldOpenHintDropdown = !match && this.currentDropdown !== 'hint';

      if (shouldOpenFilterDropdown || shouldOpenHintDropdown) {
        // `hint` is not listed as a tokenKey (since it is not a real `filter`)
        const key = match && {}.hasOwnProperty.call(match, 'key') ? match.key : 'hint';
        this.load(key, firstLoad);
      }

      gl.droplab = this.droplab;
    }

    setDropdown() {
      const { lastToken } = this.tokenizer.processTokens(this.filteredSearchInput.value);

      if (typeof lastToken === 'string') {
        // Token is not fully initialized yet because it has no value
        // Eg. token = 'label:'
        const { tokenKey } = this.tokenizer.parseToken(lastToken);
        this.loadDropdown(tokenKey);
      } else if ({}.hasOwnProperty.call(lastToken, 'key')) {
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
