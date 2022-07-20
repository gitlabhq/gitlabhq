import NewBranchForm from '~/new_branch_form';

// eslint-disable-next-line no-new
new NewBranchForm(
  document.querySelector('.js-create-branch-form'),
  JSON.parse(document.getElementById('availableRefs').innerHTML),
);
