import $ from 'jquery';
import NewBranchForm from '~/new_branch_form';

document.addEventListener('DOMContentLoaded', () => {
  new NewBranchForm($('.js-new-pipeline-form')); // eslint-disable-line no-new
});
