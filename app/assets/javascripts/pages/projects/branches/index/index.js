import initDeprecatedRemoveRowBehavior from '~/behaviors/deprecated_remove_row_behavior';
import BranchSortDropdown from '~/branches/branch_sort_dropdown';
import initDiverganceGraph from '~/branches/divergence_graph';
import initDeleteBranchButton from '~/branches/init_delete_branch_button';
import initDeleteBranchModal from '~/branches/init_delete_branch_modal';
import initDeleteMergedBranches from '~/branches/init_delete_merged_branches';

const { divergingCountsEndpoint, defaultBranch } = document.querySelector(
  '.js-branch-list',
).dataset;

initDiverganceGraph(divergingCountsEndpoint, defaultBranch);
BranchSortDropdown();
initDeprecatedRemoveRowBehavior();
initDeleteMergedBranches();

document
  .querySelectorAll('.js-delete-branch-button')
  .forEach((elem) => initDeleteBranchButton(elem));

initDeleteBranchModal();
