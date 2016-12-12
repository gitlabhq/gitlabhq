/* eslint-disable no-param-reassign */
((global) => {
  class FilteredSearchDropdownManager {
    constructor() {
      this.tokenizer = gl.FilteredSearchTokenizer;
      this.filteredSearchInput = document.querySelector('.filtered-search');

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
      }
    }

    static addWordToInput(word, addSpace) {
      const filteredSearchInput = document.querySelector('.filtered-search')
      const filteredSearchValue = filteredSearchInput.value;
      const hasExistingValue = filteredSearchValue.length !== 0;
      const { lastToken } = gl.FilteredSearchTokenizer.processTokens(filteredSearchValue);

      if (lastToken.hasOwnProperty('key')) {
        console.log(lastToken);
        // Spaces inside the token means that the token value will be escaped by quotes
        const hasQuotes = lastToken.value.indexOf(' ') !== -1;
        const lengthToRemove = hasQuotes ? lastToken.value.length + 2 : lastToken.value.length;
        filteredSearchInput.value = filteredSearchValue.slice(0, -1 * (lengthToRemove));
      }

      filteredSearchInput.value += hasExistingValue && addSpace ? ` ${word}` : word;
    }

    updateCurrentDropdownOffset() {
      this.updateDropdownOffset(this.currentDropdown);
    }

    updateDropdownOffset(key) {
      const filterIconPadding = 27;
      const offset = gl.text.getTextWidth(this.filteredSearchInput.value, this.font) + filterIconPadding;

      this.mapping[key].reference.setOffset(offset);
    }

    load(key, firstLoad = false) {
      console.log(`🦄 load ${key} dropdown`);
      const glClass = this.mapping[key].gl;
      const element = this.mapping[key].element;
      let forceShowList = false;

      if (!this.mapping[key].reference) {
        var dl = this.droplab;
        const defaultArguments = [null, dl, element, this.filteredSearchInput];
        const glArguments = defaultArguments.concat(this.mapping[key].extraArguments || []);

        this.mapping[key].reference = new (Function.prototype.bind.apply(gl[glClass], glArguments));
      }

      if (firstLoad) {
        this.mapping[key].reference.configure();
      }

      if (this.currentDropdown === 'hint') {
        // Clicked from hint dropdown
        forceShowList = true;
      }

      this.updateDropdownOffset(key);
      this.mapping[key].reference.render(firstLoad, forceShowList);

      this.currentDropdown = key;
    }

    loadDropdown(dropdownName = '') {
      let firstLoad = false;

      if(!this.droplab) {
        firstLoad = true;
        this.droplab = new DropLab();
      }

      if (!this.font) {
        this.font = window.getComputedStyle(this.filteredSearchInput).font;
      }

      const match = gl.FilteredSearchTokenKeys.get().filter(value => value.key === dropdownName.toLowerCase())[0];
      const shouldOpenFilterDropdown = match && this.currentDropdown !== match.key && this.mapping.hasOwnProperty(match.key);
      const shouldOpenHintDropdown = !match && this.currentDropdown !== 'hint';

      if (shouldOpenFilterDropdown || shouldOpenHintDropdown) {
        const key = match && match.hasOwnProperty('key') ? match.key : 'hint';
        this.load(key, firstLoad);
      }

      gl.droplab = this.droplab;
    }

    setDropdown() {
      const { lastToken } = this.tokenizer.processTokens(this.filteredSearchInput.value);

      if (typeof lastToken === 'string') {
        // Token is not fully initialized yet
        // because it has no value
        // Eg. token = 'label:'
        const { tokenKey } = this.tokenizer.parseToken(lastToken);
        this.loadDropdown(tokenKey);
      } else if (lastToken.hasOwnProperty('key')) {
        // Token has been initialized into an object
        // because it has a value
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

  global.FilteredSearchDropdownManager = FilteredSearchDropdownManager;
})(window.gl || (window.gl = {}));
