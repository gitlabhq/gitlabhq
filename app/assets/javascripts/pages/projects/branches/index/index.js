import Vue from 'vue';
import AjaxLoadingSpinner from '~/ajax_loading_spinner';
import Translate from '~/vue_shared/translate';
import deleteMergedBranchesModal from './components/delete_merged_brances_modal.vue';

Vue.use(Translate);

function createDeleteMergedBranchesModal(props) {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#delete-merged-branches-modal',
    components: {
      deleteMergedBranchesModal,
    },
    render(createElement) {
      return createElement('delete-merged-branches-modal', {
        props,
      });
    },
  });
}

export default () => {
  const deleteMergedBranchesButton = document.getElementById('delete-merged-branches-button');
  AjaxLoadingSpinner.init();
  deleteMergedBranchesButton.onclick = (event) => {
    const button = event.currentTarget;
    const props = {
      defaultBranch: button.dataset.defaultBranch,
      url: button.dataset.url,
    };
    createDeleteMergedBranchesModal(props);
  };
};
