import $ from 'jquery';
import NewBranchForm from '~/new_branch_form';

document.addEventListener('DOMContentLoaded', () => (
  new NewBranchForm($('.js-create-branch-form'), JSON.parse(document.getElementById('availableRefs').innerHTML))
));
