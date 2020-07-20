import initSettingsPanels from '~/settings_panels';
import AjaxVariableList from '~/ci_variable_list/ajax_variable_list';
import initVariableList from '~/ci_variable_list';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import AdminRunnersFilteredSearchTokenKeys from '~/filtered_search/admin_runners_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();

  initFilteredSearch({
    page: FILTERED_SEARCH.ADMIN_RUNNERS,
    filteredSearchTokenKeys: AdminRunnersFilteredSearchTokenKeys,
    anchor: FILTERED_SEARCH.GROUP_RUNNERS_ANCHOR,
  });

  if (gon.features.newVariablesUi) {
    initVariableList();
  } else {
    const variableListEl = document.querySelector('.js-ci-variable-list-section');
    // eslint-disable-next-line no-new
    new AjaxVariableList({
      container: variableListEl,
      saveButton: variableListEl.querySelector('.js-ci-variables-save-button'),
      errorBox: variableListEl.querySelector('.js-ci-variable-error-box'),
      saveEndpoint: variableListEl.dataset.saveEndpoint,
      maskableRegex: variableListEl.dataset.maskableRegex,
    });
  }
});
