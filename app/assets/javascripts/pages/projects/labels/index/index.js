import Vue from 'vue';
import initDeleteLabelModal from '~/delete_label_modal';
import initLabels from '~/init_labels';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import PromoteLabelModal from '../components/promote_label_modal.vue';
import eventHub from '../event_hub';

Vue.use(Translate);

const initLabelIndex = () => {
  initLabels();
  initDeleteLabelModal();

  const onRequestFinished = ({ labelUrl, successful }) => {
    const button = document.querySelector(
      `.js-promote-project-label-button[data-url="${labelUrl}"]`,
    );

    if (!successful) {
      button.removeAttribute('disabled');
    }
  };

  const onRequestStarted = (labelUrl) => {
    const button = document.querySelector(
      `.js-promote-project-label-button[data-url="${labelUrl}"]`,
    );
    button.setAttribute('disabled', '');
    eventHub.$once('promoteLabelModal.requestFinished', onRequestFinished);
  };

  const promoteLabelButtons = document.querySelectorAll('.js-promote-project-label-button');

  return new Vue({
    el: '#js-promote-label-modal',
    data() {
      return {
        modalProps: {
          labelTitle: '',
          labelColor: '',
          labelTextColor: '',
          url: '',
          groupName: '',
        },
      };
    },
    mounted() {
      eventHub.$on('promoteLabelModal.props', this.setModalProps);
      eventHub.$emit('promoteLabelModal.mounted');

      promoteLabelButtons.forEach((button) => {
        button.removeAttribute('disabled');
        button.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, 'promote-label-modal');
          eventHub.$once('promoteLabelModal.requestStarted', onRequestStarted);

          this.setModalProps({
            labelTitle: button.dataset.labelTitle,
            labelColor: button.dataset.labelColor,
            labelTextColor: button.dataset.labelTextColor,
            url: button.dataset.url,
            groupName: button.dataset.groupName,
          });
        });
      });
    },
    beforeDestroy() {
      eventHub.$off('promoteLabelModal.props', this.setModalProps);
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement(PromoteLabelModal, {
        props: this.modalProps,
      });
    },
  });
};
initLabelIndex();
