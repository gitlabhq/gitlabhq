import $ from 'jquery';
import NewBranchForm from '~/new_branch_form';
import setupNativeFormVariableList from '~/ci_variable_list/native_form_variable_list';

document.addEventListener('DOMContentLoaded', () => {
  new NewBranchForm($('.js-new-pipeline-form')); // eslint-disable-line no-new

  setupNativeFormVariableList({
    container: $('.js-ci-variable-list-section'),
    formField: 'variables_attributes',
  });
});
