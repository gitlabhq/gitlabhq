import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import DeleteMilestoneModal from './components/delete_milestone_modal.vue';
import eventHub from './event_hub';

export default () => {
  Vue.use(Translate);

  const onRequestFinished = ({ milestoneUrl, successful }) => {
    const button = document.querySelector(
      `.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`,
    );

    if (!successful) {
      button.removeAttribute('disabled');
    }

    button.querySelector('.js-loading-icon').classList.add('hidden');
  };

  const deleteMilestoneButtons = document.querySelectorAll('.js-delete-milestone-button');

  const onRequestStarted = (milestoneUrl) => {
    const button = document.querySelector(
      `.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`,
    );
    button.setAttribute('disabled', '');
    button.querySelector('.js-loading-icon').classList.remove('hidden');
    eventHub.$once('deleteMilestoneModal.requestFinished', onRequestFinished);
  };

  return new Vue({
    el: '#js-delete-milestone-modal',
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
      deleteMilestoneButtons.forEach((button) => {
        button.removeAttribute('disabled');
        button.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, 'delete-milestone-modal');
          eventHub.$once('deleteMilestoneModal.requestStarted', onRequestStarted);

          this.setModalProps({
            milestoneId: parseInt(button.dataset.milestoneId, 10),
            milestoneTitle: button.dataset.milestoneTitle,
            milestoneUrl: button.dataset.milestoneUrl,
            issueCount: parseInt(button.dataset.milestoneIssueCount, 10),
            mergeRequestCount: parseInt(button.dataset.milestoneMergeRequestCount, 10),
          });
        });
      });
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement(DeleteMilestoneModal, {
        props: this.modalProps,
      });
    },
  });
};
