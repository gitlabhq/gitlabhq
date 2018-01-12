import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import deleteLabelModal from './components/delete_label_modal.vue';

Vue.use(Translate);

function createDeleteLabelModal(props) {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#delete-label-modal',
    components: {
      deleteLabelModal,
    },
    render(createElement) {
      return createElement('delete-label-modal', {
        props,
      });
    },
  });
}

function getProps(event) {
  const button = event.currentTarget;
  const props = {
    labelTitle: button.dataset.labelTitle,
    labelOpenIssuesCount: parseInt(button.dataset.labelOpenIssuesCount, 10),
    labelOpenMergeRequestsCount: parseInt(button.dataset.labelOpenMergeRequestsCount, 10),
    url: button.dataset.url,
  };

  createDeleteLabelModal(props);
}

export default () => {
  const deleteLabelButtons = document.querySelectorAll('.js-delete-project-label');
  for (let i = 0; i < deleteLabelButtons.length; i += 1) {
    const button = deleteLabelButtons[i];
    button.onclick = getProps;
  }
};
