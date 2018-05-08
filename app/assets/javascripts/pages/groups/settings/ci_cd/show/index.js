import AjaxVariableList from '~/ci_variable_list/ajax_variable_list';

document.addEventListener('DOMContentLoaded', () => {
  const variableListEl = document.querySelector('.js-ci-variable-list-section');
  // eslint-disable-next-line no-new
  new AjaxVariableList({
    container: variableListEl,
    saveButton: variableListEl.querySelector('.js-secret-variables-save-button'),
    errorBox: variableListEl.querySelector('.js-ci-variable-error-box'),
    saveEndpoint: variableListEl.dataset.saveEndpoint,
  });
});
