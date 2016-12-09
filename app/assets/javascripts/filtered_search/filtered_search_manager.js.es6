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

      document.removeEventListener('page:fetch', this.cleanupWrapper);
    }

    setupMapping() {
      this.mapping = {
        author: {
          reference: null,
          gl: 'DropdownAuthor',
          element: document.querySelector('#js-dropdown-author'),
        },
        assignee: {
          reference: null,
          gl: 'DropdownAssignee',
          element: document.querySelector('#js-dropdown-assignee'),
        },
        milestone: {
          reference: null,
          gl: 'DropdownMilestone',
          element: document.querySelector('#js-dropdown-milestone'),
        },
        label: {
          reference: null,
          gl: 'DropdownLabel',
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

    load(key, firstLoad = false) {
      console.log(`🦄 load ${key} dropdown`);
      const glClass = this.mapping[key].gl;
      const element = this.mapping[key].element;
      const filterIconPadding = 27;
      const dropdownOffset = gl.text.getTextWidth(this.filteredSearchInput.value, this.font) + filterIconPadding;

      if (!this.mapping[key].reference) {
        this.mapping[key].reference = new gl[glClass](this.droplab, element, this.filteredSearchInput);
      }

      if (firstLoad) {
        this.mapping[key].reference.configure();
      }

      this.mapping[key].reference.setOffset(dropdownOffset);
      this.mapping[key].reference.render(firstLoad);

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
      this.filteredSearchInput.addEventListener('input', this.setDropdown.bind(this));
      this.filteredSearchInput.addEventListener('input', toggleClearSearchButton);
      this.filteredSearchInput.addEventListener('keydown', this.checkForEnter.bind(this));
      this.clearSearchButton.addEventListener('click', this.clearSearch.bind(this));
    }

    clearSearch(e) {
      e.stopPropagation();
      e.preventDefault();

      this.filteredSearchInput.value = '';
      this.clearSearchButton.classList.add('hidden');
      dropdownHint.resetFilters();
      this.loadDropdown('hint');
    }

    checkForEnter(e) {
      // Enter KeyCode
      if (e.keyCode === 13) {
        e.stopPropagation();
        e.preventDefault();
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
