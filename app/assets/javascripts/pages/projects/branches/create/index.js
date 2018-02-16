import NewBranchForm from '~/new_branch_form';

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new NewBranchForm($('.js-create-branch-form'), JSON.parse(document.getElementById('availableRefs').innerHTML));
});
