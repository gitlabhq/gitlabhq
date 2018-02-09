import NewBranchForm from '~/new_branch_form';

export default () => new NewBranchForm($('.js-create-branch-form'), JSON.parse(document.getElementById('availableRefs').innerHTML));
