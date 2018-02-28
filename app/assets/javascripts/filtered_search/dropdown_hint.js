import Filter from '~/droplab/plugins/filter';
import './filtered_search_dropdown';

class DropdownHint extends gl.FilteredSearchDropdown {
  constructor(options = {}) {
    const { input, tokenKeys } = options;
    super(options);
    this.config = {
      Filter: {
        template: 'hint',
        filterFunction: gl.DropdownUtils.filterHint.bind(null, {
          input,
          allowedKeys: tokenKeys.getKeys(),
        }),
      },
    };
    this.tokenKeys = tokenKeys;
  }

  itemClicked(e) {
    const { selected } = e.detail;

    if (selected.tagName === 'LI') {
      if (selected.hasAttribute('data-value')) {
        this.dismissDropdown();
      } else if (selected.getAttribute('data-action') === 'submit') {
        this.dismissDropdown();
        this.dispatchFormSubmitEvent();
      } else {
        const token = selected.querySelector('.js-filter-hint').innerText.trim();
        const tag = selected.querySelector('.js-filter-tag').innerText.trim();

        if (tag.length) {
          // Get previous input values in the input field and convert them into visual tokens
          const previousInputValues = this.input.value.split(' ');
          const searchTerms = [];

          previousInputValues.forEach((value, index) => {
            searchTerms.push(value);

            if (index === previousInputValues.length - 1
              && token.indexOf(value.toLowerCase()) !== -1) {
              searchTerms.pop();
            }
          });

          if (searchTerms.length > 0) {
            gl.FilteredSearchVisualTokens.addSearchVisualToken(searchTerms.join(' '));
          }

          gl.FilteredSearchDropdownManager.addWordToInput(token.replace(':', ''), '', false, this.container);
        }
        this.dismissDropdown();
        this.dispatchInputEvent();
      }
    }
  }

  renderContent() {
    const dropdownData = this.tokenKeys.get()
      .map(tokenKey => ({
        icon: `fa-${tokenKey.icon}`,
        hint: tokenKey.key,
        tag: `<${tokenKey.symbol}${tokenKey.key}>`,
        type: tokenKey.type,
      }));

    this.droplab.changeHookList(this.hookId, this.dropdown, [Filter], this.config);
    this.droplab.setData(this.hookId, dropdownData);
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [Filter], this.config).init();
  }
}

window.gl = window.gl || {};
gl.DropdownHint = DropdownHint;
