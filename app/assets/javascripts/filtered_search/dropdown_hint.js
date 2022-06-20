import { __ } from '~/locale';
import Filter from './droplab/plugins/filter';
import DropdownUtils from './dropdown_utils';
import FilteredSearchDropdown from './filtered_search_dropdown';
import FilteredSearchDropdownManager from './filtered_search_dropdown_manager';
import FilteredSearchVisualTokens from './filtered_search_visual_tokens';

export default class DropdownHint extends FilteredSearchDropdown {
  constructor(options = {}) {
    const { input, tokenKeys } = options;
    super(options);
    this.config = {
      Filter: {
        template: 'hint',
        filterFunction: DropdownUtils.filterHint.bind(null, {
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
      if (Object.prototype.hasOwnProperty.call(selected.dataset, 'value')) {
        this.dismissDropdown();
      } else if (selected.dataset.action === 'submit') {
        this.dismissDropdown();
        this.dispatchFormSubmitEvent();
      } else {
        const filterItemEl = selected.closest('.filter-dropdown-item');
        const { hint: token, tag } = filterItemEl.dataset;

        if (tag.length) {
          // Get previous input values in the input field and convert them into visual tokens
          const previousInputValues = this.input.value.split(' ');
          const searchTerms = [];

          previousInputValues.forEach((value, index) => {
            searchTerms.push(value);

            if (
              index === previousInputValues.length - 1 &&
              token.indexOf(value.toLowerCase()) !== -1
            ) {
              searchTerms.pop();
            }
          });

          if (searchTerms.length > 0) {
            FilteredSearchVisualTokens.addSearchVisualToken(searchTerms.join(' '));
          }

          const key = token.replace(':', '');
          const { uppercaseTokenName } = this.tokenKeys.searchByKey(key);

          FilteredSearchDropdownManager.addWordToInput({
            tokenName: key,
            clicked: false,
            options: {
              uppercaseTokenName,
            },
          });
        }
        this.dismissDropdown();
        this.dispatchInputEvent();
      }
    }
  }

  renderContent() {
    const searchItem = [
      {
        hint: 'search',
        tag: 'search',
        formattedKey: __('Search for this text'),
        icon: `${gon.sprite_icons}#search`,
      },
    ];

    const dropdownData = this.tokenKeys
      .get()
      .map((tokenKey) => ({
        icon: `${gon.sprite_icons}#${tokenKey.icon}`,
        hint: tokenKey.key,
        tag: `:${tokenKey.tag}`,
        type: tokenKey.type,
        formattedKey: tokenKey.formattedKey,
      }))
      .concat(searchItem);

    this.droplab.changeHookList(this.hookId, this.dropdown, [Filter], this.config);
    this.droplab.setData(this.hookId, dropdownData);

    super.renderContent();
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [Filter], this.config).init();
  }
}
