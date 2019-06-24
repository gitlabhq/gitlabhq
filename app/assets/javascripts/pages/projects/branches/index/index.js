import AjaxLoadingSpinner from '~/ajax_loading_spinner';
import DeleteModal from '~/branches/branches_delete_modal';
import initDiverganceGraph from '~/branches/divergence_graph';

document.addEventListener('DOMContentLoaded', () => {
  AjaxLoadingSpinner.init();
  new DeleteModal(); // eslint-disable-line no-new
  initDiverganceGraph();
});
