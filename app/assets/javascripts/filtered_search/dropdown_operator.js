import Filter from '~/droplab/plugins/filter';
import { __ } from '~/locale';
import DropdownUtils from './dropdown_utils';
import FilteredSearchDropdown from './filtered_search_dropdown';
import FilteredSearchDropdownManager from './filtered_search_dropdown_manager';
import FilteredSearchVisualTokens from './filtered_search_visual_tokens';

export default class DropdownOperator extends FilteredSearchDropdown {
  constructor(options = {}) {
    const { input, tokenKeys } = options;
    super(options);

    this.config = {
      Filter: {
        filterFunction: DropdownUtils.filterWithSymbol.bind(null, '', input),
        template: 'title',
      },
    };
    this.tokenKeys = tokenKeys;
  }

  itemClicked(e) {
    const { selected } = e.detail;

    if (selected.tagName === 'LI') {
      if (selected.hasAttribute('data-value')) {
        const name = FilteredSearchVisualTokens.getLastTokenPartial();
        const operator = selected.dataset.value;

        FilteredSearchVisualTokens.removeLastTokenPartial();
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: name,
          tokenOperator: operator,
          clicked: false,
        });
      }
    }
    this.dismissDropdown();
    this.dispatchInputEvent();
  }

  renderContent(forceShowList = false, dropdownName = '') {
    const dropdownData = [
      {
        tag: 'equal',
        type: 'string',
        title: '=',
        help: __('is'),
      },
    ];
    const dropdownToken = this.tokenKeys.searchByKey(dropdownName.toLowerCase());

    if (!dropdownToken?.hideNotEqual) {
      dropdownData.push({
        tag: 'not-equal',
        type: 'string',
        title: '!=',
        help: __('is not'),
      });
    }

    this.droplab.changeHookList(this.hookId, this.dropdown, [Filter], this.config);
    this.droplab.setData(this.hookId, dropdownData);
    super.renderContent(forceShowList);
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [Filter], this.config).init();
  }
}
