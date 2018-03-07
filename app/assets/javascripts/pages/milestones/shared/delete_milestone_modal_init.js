import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import deleteMilestoneModal from './components/delete_milestone_modal.vue';
import eventHub from './event_hub';

export default () => {
  Vue.use(Translate);

  const onRequestFinished = ({ milestoneUrl, successful }) => {
    const button = document.querySelector(`.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`);

    if (!successful) {
      button.removeAttribute('disabled');
    }

    button.querySelector('.js-loading-icon').classList.add('hidden');
  };

  const onRequestStarted = (milestoneUrl) => {
    const button = document.querySelector(`.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`);
    button.setAttribute('disabled', '');
    button.querySelector('.js-loading-icon').classList.remove('hidden');
    eventHub.$once('deleteMilestoneModal.requestFinished', onRequestFinished);
  };

  const onDeleteButtonClick = (event) => {
    const button = event.currentTarget;
    const modalProps = {
      milestoneId: parseInt(button.dataset.milestoneId, 10),
      milestoneTitle: button.dataset.milestoneTitle,
      milestoneUrl: button.dataset.milestoneUrl,
      issueCount: parseInt(button.dataset.milestoneIssueCount, 10),
      mergeRequestCount: parseInt(button.dataset.milestoneMergeRequestCount, 10),
    };
    eventHub.$once('deleteMilestoneModal.requestStarted', onRequestStarted);
    eventHub.$emit('deleteMilestoneModal.props', modalProps);
  };

  const deleteMilestoneButtons = document.querySelectorAll('.js-delete-milestone-button');
  deleteMilestoneButtons.forEach((button) => {
    button.addEventListener('click', onDeleteButtonClick);
  });

  eventHub.$once('deleteMilestoneModal.mounted', () => {
    deleteMilestoneButtons.forEach((button) => {
      button.removeAttribute('disabled');
    });
  });

  return new Vue({
    el: '#delete-milestone-modal',
    components: {
      deleteMilestoneModal,
    },
    data() {
      return {
        modalProps: {
          milestoneId: -1,
          milestoneTitle: '',
          milestoneUrl: '',
          issueCount: -1,
          mergeRequestCount: -1,
        },
      };
    },
    mounted() {
      eventHub.$on('deleteMilestoneModal.props', this.setModalProps);
      eventHub.$emit('deleteMilestoneModal.mounted');
    },
    beforeDestroy() {
      eventHub.$off('deleteMilestoneModal.props', this.setModalProps);
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement(deleteMilestoneModal, {
        props: this.modalProps,
      });
    },
  });
};
