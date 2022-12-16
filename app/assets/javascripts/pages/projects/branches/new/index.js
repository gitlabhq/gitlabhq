import NewBranchForm from '~/new_branch_form';
import initNewBranchRefSelector from '~/branches/init_new_branch_ref_selector';

initNewBranchRefSelector();
// eslint-disable-next-line no-new
new NewBranchForm(document.querySelector('.js-create-branch-form'));
