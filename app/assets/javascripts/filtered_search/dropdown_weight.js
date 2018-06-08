import FilteredSearchDropdown from './filtered_search_dropdown';
import DropdownUtils from './dropdown_utils';
import CustomNumber from '../droplab/plugins/custom_number';

export default class DropdownWeight extends FilteredSearchDropdown {
  constructor(options = {}) {
    super(options);

    this.defaultOptions = Array.from(Array(21).keys());

    this.config = {
      CustomNumber: {
        defaultOptions: this.defaultOptions,
      },
    };
  }

  itemClicked(e) {
    super.itemClicked(e, selected => {
      const title = selected.querySelector('.js-data-value').innerText.trim();
      return `${DropdownUtils.getEscapedText(title)}`;
    });
  }

  renderContent(forceShowList = false) {
    this.droplab.changeHookList(this.hookId, this.dropdown, [CustomNumber], this.config);

    const defaultDropdownOptions = this.defaultOptions.map(o => ({ id: o, title: o }));
    this.droplab.setData(defaultDropdownOptions);

    super.renderContent(forceShowList);
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [CustomNumber], this.config).init();
  }
}
