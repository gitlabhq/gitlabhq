import DropLab from '~/droplab/drop_lab';
import FilteredSearchContainer from './container';

class FilteredSearchDropdownManager {
  constructor(baseEndpoint = '', tokenizer, page) {
    this.container = FilteredSearchContainer.container;
    this.baseEndpoint = baseEndpoint.replace(/\/$/, '');
    this.tokenizer = tokenizer;
    this.filteredSearchTokenKeys = gl.FilteredSearchTokenKeys;
    this.filteredSearchInput = this.container.querySelector('.filtered-search');
    this.page = page;

    if (this.page === 'issues' || this.page === 'boards') {
      this.filteredSearchTokenKeys = gl.FilteredSearchTokenKeysIssuesEE;
    }

    this.setupMapping();

    this.cleanupWrapper = this.cleanup.bind(this);
    document.addEventListener('beforeunload', this.cleanupWrapper);
  }

  cleanup() {
    if (this.droplab) {
      this.droplab.destroy();
      this.droplab = null;
    }

    this.setupMapping();

    document.removeEventListener('beforeunload', this.cleanupWrapper);
  }

  setupMapping() {
    this.mapping = {
      author: {
        reference: null,
        gl: 'DropdownUser',
        element: this.container.querySelector('#js-dropdown-author'),
      },
      assignee: {
        reference: null,
        gl: 'DropdownUser',
        element: this.container.querySelector('#js-dropdown-assignee'),
      },
      milestone: {
        reference: null,
        gl: 'DropdownNonUser',
        extraArguments: {
          endpoint: `${this.baseEndpoint}/milestones.json`,
          symbol: '%',
        },
        element: this.container.querySelector('#js-dropdown-milestone'),
      },
      label: {
        reference: null,
        gl: 'DropdownNonUser',
        extraArguments: {
          endpoint: `${this.baseEndpoint}/labels.json`,
          symbol: '~',
        },
        element: this.container.querySelector('#js-dropdown-label'),
      },
      hint: {
        reference: null,
        gl: 'DropdownHint',
        element: this.container.querySelector('#js-dropdown-hint'),
      },
    };

    if (this.page === 'issues' || this.page === 'boards') {
      this.mapping.weight = {
        reference: null,
        gl: 'DropdownNonUser',
        element: this.container.querySelector('#js-dropdown-weight'),
      };
    }
  }

  static addWordToInput(tokenName, tokenValue = '', clicked = false) {
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');

    gl.FilteredSearchVisualTokens.addFilterVisualToken(tokenName, tokenValue);
    input.value = '';

    if (clicked) {
      gl.FilteredSearchVisualTokens.moveInputToTheRight();
    }
  }

  updateCurrentDropdownOffset() {
    this.updateDropdownOffset(this.currentDropdown);
  }

  updateDropdownOffset(key) {
    // Always align dropdown with the input field
    let offset = this.filteredSearchInput.getBoundingClientRect().left - this.container.querySelector('.scroll-container').getBoundingClientRect().left;

    const maxInputWidth = 240;
    const currentDropdownWidth = this.mapping[key].element.clientWidth || maxInputWidth;

    // Make sure offset never exceeds the input container
    const offsetMaxWidth = this.container.querySelector('.scroll-container').clientWidth - currentDropdownWidth;
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
      const defaultArguments = {
        droplab: this.droplab,
        dropdown: element,
        input: this.filteredSearchInput,
        tokenKeys: this.filteredSearchTokenKeys,
        filter: key,
      };
      const extraArguments = mappingKey.extraArguments || {};
      const glArguments = Object.assign({}, defaultArguments, extraArguments);

      // Passing glArguments to `new gl[glClass](<arguments>)`
      mappingKey.reference =
        new (Function.prototype.bind.apply(gl[glClass], [null, glArguments]))();
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

    const match = this.filteredSearchTokenKeys.searchByKey(dropdownName.toLowerCase());
    const shouldOpenFilterDropdown = match && this.currentDropdown !== match.key
      && this.mapping[match.key];
    const shouldOpenHintDropdown = !match && this.currentDropdown !== 'hint';

    if (shouldOpenFilterDropdown || shouldOpenHintDropdown) {
      const key = match && match.key ? match.key : 'hint';
      this.load(key, firstLoad);
    }
  }

  setDropdown() {
    const query = gl.DropdownUtils.getSearchQuery(true);
    const { lastToken, searchToken } =
      this.tokenizer.processTokens(query, this.filteredSearchTokenKeys.getKeys());

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
    if (!this.currentDropdown) {
      return;
    }

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
