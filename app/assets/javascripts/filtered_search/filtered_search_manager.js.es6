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

  let dropdownHint;
  let dropdownAuthor;
  let dropdownAssignee;
  let dropdownMilestone;
  let dropdownLabel;

  class FilteredSearchManager {
    constructor() {
      this.tokenizer = gl.FilteredSearchTokenizer;
      this.bindEvents();
      loadSearchParamsFromURL();
      this.setDropdown();

      document.addEventListener('page:change', this.cleanup);
    }

    cleanup() {
      console.log('cleanup')

      if (this.droplab) {
        this.droplab.destroy();
        this.droplab = null;
      }

      dropdownHint = null;
      dropdownAuthor = null;
      dropdownAssignee = null;
      dropdownMilestone = null;
      dropdownLabel = null;

      document.removeEventListener('page:change', this.cleanup);
    }

    static addWordToInput(word, addSpace) {
      const filteredSearchValue = document.querySelector('.filtered-search').value;
      const hasExistingValue = filteredSearchValue.length !== 0;

      const { lastToken } = gl.FilteredSearchTokenizer.processTokens(filteredSearchValue);
      if (lastToken.hasOwnProperty('key')) {
        console.log(lastToken);
        // Spaces inside the token means that the token value will be escaped by quotes
        const hasQuotes = lastToken.value.indexOf(' ') !== -1;

        const lengthToRemove = hasQuotes ? lastToken.value.length + 2 : lastToken.value.length;
        document.querySelector('.filtered-search').value = filteredSearchValue.slice(0, -1 * (lengthToRemove));
      }

      document.querySelector('.filtered-search').value += hasExistingValue && addSpace ? ` ${word}` : word;
    }

    loadDropdown(dropdownName = '', hideDropdown) {
      let firstLoad = false;
      const filteredSearch = document.querySelector('.filtered-search');

      if(!this.droplab) {
        firstLoad = true;
        this.droplab = new DropLab();
      }

      dropdownName = dropdownName.toLowerCase();

      const filterIconPadding = 27;
      const match = gl.FilteredSearchTokenKeys.get().filter(value => value.key === dropdownName)[0];

      if (!this.font) {
        this.font = window.getComputedStyle(filteredSearch).font;
      }

      if (match && this.currentDropdown !== match.key) {
        console.log(`🦄 load ${match.key} dropdown`);

        const dynamicDropdownPadding = 12;
        const dropdownOffset = gl.text.getTextWidth(filteredSearch.value, this.font) + filterIconPadding + dynamicDropdownPadding;
        const dropdownAuthorElement = document.querySelector('#js-dropdown-author');
        const dropdownAssigneeElement = document.querySelector('#js-dropdown-assignee');
        const dropdownMilestoneElement = document.querySelector('#js-dropdown-milestone');
        const dropdownLabelElemenet = document.querySelector('#js-dropdown-label');

        this.dismissCurrentDropdown();
        this.currentDropdown = match.key;

        if (match.key === 'author') {
          if (!dropdownAuthor) {
            dropdownAuthor = new gl.DropdownAuthor(this.droplab, dropdownAuthorElement, filteredSearch);
          }

          dropdownAuthor.setOffset(dropdownOffset);
          dropdownAuthor.render();
        } else if (match.key === 'assignee') {
          if (!dropdownAssignee) {
            dropdownAssignee = new gl.DropdownAssignee(this.droplab, dropdownAssigneeElement, filteredSearch);
          }

          dropdownAssignee.setOffset(dropdownOffset);
          dropdownAssignee.render();
        } else if (match.key === 'milestone') {
          if (!dropdownMilestone) {
            dropdownMilestone = new gl.DropdownMilestone(this.droplab, dropdownMilestoneElement, filteredSearch);
          }

          dropdownMilestone.setOffset(dropdownOffset);
          dropdownMilestone.render();
        } else if (match.key === 'label') {
          if (!dropdownLabel) {
            dropdownLabel = new gl.DropdownLabel(this.droplab, dropdownLabelElemenet, filteredSearch);
          }

          dropdownLabel.setOffset(dropdownOffset);
          dropdownLabel.render();
        }

      } else if (!match && this.currentDropdown !== 'hint') {
        console.log('🦄 load hint dropdown');

        const dropdownOffset = gl.text.getTextWidth(filteredSearch.value, this.font) + filterIconPadding;
        const dropdownHintElement = document.querySelector('#js-dropdown-hint');

        this.dismissCurrentDropdown();
        this.currentDropdown = 'hint';
        if (!dropdownHint) {
          dropdownHint = new gl.DropdownHint(this.droplab, dropdownHintElement, filteredSearch);
        }

        if (firstLoad) {
          dropdownHint.configure();
        }

        dropdownHint.setOffset(dropdownOffset);
        dropdownHint.render(firstLoad);
      }
    }

    dismissCurrentDropdown() {
      // if (this.currentDropdown === 'hint') {
      //   dropdownHint.hide();
      // } else if (this.currentDropdown === 'author') {
      //   // dropdownAuthor.hide();
      // }
    }

    setDropdown() {
      const { lastToken } = this.tokenizer.processTokens(document.querySelector('.filtered-search').value);

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
      const filteredSearchInput = document.querySelector('.filtered-search');

      filteredSearchInput.addEventListener('input', this.setDropdown.bind(this));
      filteredSearchInput.addEventListener('input', toggleClearSearchButton);
      filteredSearchInput.addEventListener('keydown', this.checkForEnter.bind(this));
      document.querySelector('.clear-search').addEventListener('click', this.clearSearch.bind(this));
    }

    clearSearch(e) {
      e.stopPropagation();
      e.preventDefault();

      document.querySelector('.filtered-search').value = '';
      document.querySelector('.clear-search').classList.add('hidden');
      dropdownHint.resetFilters();
      this.loadDropdown('hint', true);
    }

    checkDropdownToken(e) {
      const input = e.target.value;
      const { lastToken } = this.tokenizer.processTokens(input);

      // Check for dropdown token
      if (lastToken[lastToken.length - 1] === ':') {
        const token = lastToken.slice(0, -1);
      }
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
