import Filter from '~/droplab/plugins/filter';
import { __ } from '~/locale';
import FilteredSearchDropdown from './filtered_search_dropdown';
import DropdownUtils from './dropdown_utils';
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
        const operator = selected.dataset.value;
        FilteredSearchVisualTokens.removeLastTokenPartial();
        FilteredSearchDropdownManager.addWordToInput({
          tokenName: this.filter,
          tokenOperator: operator,
          clicked: false,
        });
      }
    }
    this.dismissDropdown();
    this.dispatchInputEvent();
  }

  renderContent(forceShowList = false) {
    this.filter = FilteredSearchVisualTokens.getLastTokenPartial();

    const dropdownData = [
      {
        tag: 'equal',
        type: 'string',
        title: '=',
        help: __('Is'),
      },
      {
        tag: 'not-equal',
        type: 'string',
        title: '!=',
        help: __('Is not'),
      },
    ];
    this.droplab.changeHookList(this.hookId, this.dropdown, [Filter], this.config);
    this.droplab.setData(this.hookId, dropdownData);
    super.renderContent(forceShowList);
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [Filter], this.config).init();
  }
}
