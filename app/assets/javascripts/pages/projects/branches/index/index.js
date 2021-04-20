import initDeprecatedRemoveRowBehavior from '~/behaviors/deprecated_remove_row_behavior';
import AjaxLoadingSpinner from '~/branches/ajax_loading_spinner';
import BranchSortDropdown from '~/branches/branch_sort_dropdown';
import DeleteModal from '~/branches/branches_delete_modal';
import initDiverganceGraph from '~/branches/divergence_graph';

AjaxLoadingSpinner.init();
new DeleteModal(); // eslint-disable-line no-new

const { divergingCountsEndpoint, defaultBranch } = document.querySelector(
  '.js-branch-list',
).dataset;

initDiverganceGraph(divergingCountsEndpoint, defaultBranch);
BranchSortDropdown();
initDeprecatedRemoveRowBehavior();
