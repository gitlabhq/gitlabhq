import Flash from '../flash';
import AjaxFilter from '../droplab/plugins/ajax_filter';
import FilteredSearchDropdown from './filtered_search_dropdown';
import { addClassIfElementExists } from '../lib/utils/dom_utils';
import DropdownUtils from './dropdown_utils';
import FilteredSearchTokenizer from './filtered_search_tokenizer';

export default class DropdownUser extends FilteredSearchDropdown {
  constructor(options = {}) {
    const { tokenKeys } = options;
    super(options);
    this.config = {
      AjaxFilter: {
        endpoint: `${gon.relative_url_root || ''}/autocomplete/users.json`,
        searchKey: 'search',
        params: {
          active: true,
          group_id: this.getGroupId(),
          project_id: this.getProjectId(),
          current_user: true,
        },
        searchValueFunction: this.getSearchInput.bind(this),
        loadingTemplate: this.loadingTemplate,
        onLoadingFinished: () => {
          this.hideCurrentUser();
        },
        onError() {
          /* eslint-disable no-new */
          new Flash('An error occurred fetching the dropdown data.');
          /* eslint-enable no-new */
        },
      },
    };
    this.tokenKeys = tokenKeys;
  }

  hideCurrentUser() {
    addClassIfElementExists(this.dropdown.querySelector('.js-current-user'), 'hidden');
  }

  itemClicked(e) {
    super.itemClicked(e,
      selected => selected.querySelector('.dropdown-light-content').innerText.trim());
  }

  renderContent(forceShowList = false) {
    this.droplab.changeHookList(this.hookId, this.dropdown, [AjaxFilter], this.config);
    super.renderContent(forceShowList);
  }

  getGroupId() {
    return this.input.getAttribute('data-group-id');
  }

  getProjectId() {
    return this.input.getAttribute('data-project-id');
  }

  getSearchInput() {
    const query = DropdownUtils.getSearchInput(this.input);
    const { lastToken } = FilteredSearchTokenizer.processTokens(query, this.tokenKeys.get());

    let value = lastToken || '';

    if (value[0] === '@') {
      value = value.slice(1);
    }

    // Removes the first character if it is a quotation so that we can search
    // with multiple words
    if (value[0] === '"' || value[0] === '\'') {
      value = value.slice(1);
    }

    return value;
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [AjaxFilter], this.config).init();
  }
}
