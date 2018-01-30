import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import deleteBranchModal from '../components/delete_branch_modal_component.vue';
import eventHub from '../shared/event_hub';

export default () => {
  Vue.use(Translate);

  const onRequestFinished = ({ branchUrl, successful }) => {
    const button = document.querySelector(`.js-delete-branch[data-delete-path="${branchUrl}"]`);

    if (!successful) {
      button.removeAttribute('disabled');
    }
  };

  const onRequestStarted = (branchUrl) => {
    const button = document.querySelector(`.js-delete-branch[data-delete-path="${branchUrl}"]`);
    button.setAttribute('disabled', '');
    eventHub.$once('deleteBranchModal.requestFinished', onRequestFinished);
  };

  const onDeleteButtonClick = (event) => {
    const button = event.currentTarget;
    const modalProps = {
      deletePath: button.dataset.deletePath,
      branchName: button.dataset.branchName,
      isMerged: convertPermissionToBoolean(button.dataset.isMerged) || false,
      isProtected: convertPermissionToBoolean(button.dataset.isProtected) || false,
      rootRef: button.dataset.rootRef,
      redirectUrl: button.dataset.redirectUrl,
    };
    eventHub.$once('deleteBranchModal.requestStarted', onRequestStarted);
    eventHub.$emit('deleteBranchModal.props', modalProps);
  };

  const deleteBranchButtons = document.querySelectorAll('.js-delete-branch');
  for (let i = 0; i < deleteBranchButtons.length; i += 1) {
    const button = deleteBranchButtons[i];
    button.addEventListener('click', onDeleteButtonClick);
  }

  eventHub.$once('deleteBranchModal.mounted', () => {
    for (let i = 0; i < deleteBranchButtons.length; i += 1) {
      const button = deleteBranchButtons[i];
      button.removeAttribute('disabled');
    }
  });

  return new Vue({
    el: '#delete-branch-modal',
    components: {
      deleteBranchModal,
    },
    data() {
      return {
        modalProps: {
          deletePath: '',
          branchName: '',
          isMerged: false,
          isProtected: false,
          rootRef: '',
          redirectUrl: '',
        },
      };
    },
    mounted() {
      eventHub.$on('deleteBranchModal.props', this.setModalProps);
      eventHub.$emit('deleteBranchModal.mounted');
    },
    beforeDestroy() {
      eventHub.$off('deleteBranchModal.props', this.setModalProps);
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement('delete-branch-modal', {
        props: this.modalProps,
      });
    },
  });
};
