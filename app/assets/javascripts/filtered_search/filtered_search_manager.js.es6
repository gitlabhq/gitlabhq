/* eslint-disable no-param-reassign */
((global) => {
  function toggleClearSearchButton(e) {
    const clearSearchButton = document.querySelector('.clear-search');

    if (e.target.value) {
      clearSearchButton.classList.remove('hidden');
    } else {
      clearSearchButton.classList.add('hidden');
    }
  }

  function loadSearchParamsFromURL() {
    // We can trust that each param has one & since values containing & will be encoded
    // Remove the first character of search as it is always ?
    const params = window.location.search.slice(1).split('&');
    let inputValue = '';

    params.forEach((p) => {
      const split = p.split('=');
      const key = decodeURIComponent(split[0]);
      const value = split[1];

      // Check if it matches edge conditions listed in gl.FilteredSearchTokenKeys.get()
      let conditionIndex = 0;
      const validCondition = gl.FilteredSearchTokenKeys.get()
        .filter(v => v.conditions && v.conditions.filter((c, index) => {
          if (c.url === p) {
            conditionIndex = index;
          }
          return c.url === p;
        })[0])[0];

      if (validCondition) {
        inputValue += `${validCondition.key}:${validCondition.conditions[conditionIndex].keyword}`;
        inputValue += ' ';
      } else {
        // Sanitize value since URL converts spaces into +
        // Replace before decode so that we know what was originally + versus the encoded +
        const sanitizedValue = value ? decodeURIComponent(value.replace(/[+]/g, ' ')) : value;
        const match = gl.FilteredSearchTokenKeys.get().filter(t => key === `${t.key}_${t.param}`)[0];

        if (match) {
          const sanitizedKey = key.slice(0, key.indexOf('_'));
          const valueHasSpace = sanitizedValue.indexOf(' ') !== -1;
          const symbol = match.symbol;

          const preferredQuotations = '"';
          let quotationsToUse = preferredQuotations;

          if (valueHasSpace) {
            // Prefer ", but use ' if required
            quotationsToUse = sanitizedValue.indexOf(preferredQuotations) === -1 ? preferredQuotations : '\'';
          }

          inputValue += valueHasSpace ? `${sanitizedKey}:${symbol}${quotationsToUse}${sanitizedValue}${quotationsToUse}` : `${sanitizedKey}:${symbol}${sanitizedValue}`;
          inputValue += ' ';
        } else if (!match && key === 'search') {
          inputValue += sanitizedValue;
          inputValue += ' ';
        }
      }
    });

    // Trim the last space value
    document.querySelector('.filtered-search').value = inputValue.trim();

    if (inputValue.trim()) {
      document.querySelector('.clear-search').classList.remove('hidden');
    }
  }

  class FilteredSearchManager {
    constructor() {
      this.tokenizer = gl.FilteredSearchTokenizer;
      this.filteredSearchInput = document.querySelector('.filtered-search');
      this.clearSearchButton = document.querySelector('.clear-search');

      this.setupMapping();
      this.bindEvents();
      loadSearchParamsFromURL();
      this.setDropdown();

      this.cleanupWrapper = this.cleanup.bind(this);
      document.addEventListener('page:fetch', this.cleanupWrapper);
    }

    cleanup() {
      console.log('cleanup')

      if (this.droplab) {
        this.droplab.destroy();
        this.droplab = null;
      }

      this.setupMapping();

      this.unbindEvents();
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

    bindEvents() {
      this.setDropdownWrapper = this.setDropdown.bind(this);
      this.checkForEnterWrapper = this.checkForEnter.bind(this);
      this.clearSearchWrapper = this.clearSearch.bind(this);
      this.checkForBackspaceWrapper = this.checkForBackspace.bind(this);

      this.filteredSearchInput.addEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.addEventListener('input', toggleClearSearchButton);
      this.filteredSearchInput.addEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.addEventListener('keyup', this.checkForBackspaceWrapper);
      this.clearSearchButton.addEventListener('click', this.clearSearchWrapper);
    }

    unbindEvents() {
      this.filteredSearchInput.removeEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.removeEventListener('input', toggleClearSearchButton);
      this.filteredSearchInput.removeEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.removeEventListener('keyup', this.checkForBackspaceWrapper);
      this.clearSearchButton.removeEventListener('click', this.clearSearchWrapper);
    }

    clearSearch(e) {
      e.stopPropagation();
      e.preventDefault();

      this.filteredSearchInput.value = '';
      this.clearSearchButton.classList.add('hidden');


      // Force current dropdown to hide
      this.mapping[this.currentDropdown].reference.hideDropdown();

      // Re-Load dropdown
      this.setDropdown();

      // Reset filters for current dropdown
      this.mapping[this.currentDropdown].reference.resetFilters();

      // Reposition dropdown so that it is aligned with cursor
      this.updateDropdownOffset(this.currentDropdown);
    }

    checkForBackspace(e) {
      if (e.keyCode === 8) {
        // Reposition dropdown so that it is aligned with cursor
        this.updateDropdownOffset(this.currentDropdown);
      }
    }

    checkForEnter(e) {
      // Enter KeyCode
      if (e.keyCode === 13) {
        e.stopPropagation();
        e.preventDefault();

        // Prevent droplab from opening dropdown
        this.droplab.destroy();

        this.search();
      }
    }

    search() {
      console.log('search');
      let path = '?scope=all&utf8=✓';

      // Check current state
      const currentPath = window.location.search;
      const stateIndex = currentPath.indexOf('state=');
      const defaultState = 'opened';
      let currentState = defaultState;

      const { tokens, searchToken } = this.tokenizer.processTokens(document.querySelector('.filtered-search').value);

      if (stateIndex !== -1) {
        const remaining = currentPath.slice(stateIndex + 6);
        const separatorIndex = remaining.indexOf('&');

        currentState = separatorIndex === -1 ? remaining : remaining.slice(0, separatorIndex);
      }

      path += `&state=${currentState}`;
      tokens.forEach((token) => {
        const match = gl.FilteredSearchTokenKeys.get().filter(t => t.key === token.key)[0];
        let tokenPath = '';

        if (token.wildcard && match.conditions) {
          const condition = match.conditions
            .filter(c => c.keyword === token.value.toLowerCase())[0];

          if (condition) {
            tokenPath = `${condition.url}`;
          }
        } else if (!token.wildcard) {
          // Remove the wildcard token
          tokenPath = `${token.key}_${match.param}=${encodeURIComponent(token.value.slice(1))}`;
        } else {
          tokenPath = `${token.key}_${match.param}=${encodeURIComponent(token.value)}`;
        }

        path += `&${tokenPath}`;
      });

      if (searchToken) {
        path += `&search=${encodeURIComponent(searchToken)}`;
      }

      window.location = path;
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));
