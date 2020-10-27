import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import initLabels from '~/init_labels';
import eventHub from '../event_hub';
import PromoteLabelModal from '../components/promote_label_modal.vue';

Vue.use(Translate);

const initLabelIndex = () => {
  initLabels();

  const onRequestFinished = ({ labelUrl, successful }) => {
    const button = document.querySelector(
      `.js-promote-project-label-button[data-url="${labelUrl}"]`,
    );

    if (!successful) {
      button.removeAttribute('disabled');
    }
  };

  const onRequestStarted = labelUrl => {
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

      promoteLabelButtons.forEach(button => {
        button.removeAttribute('disabled');
        button.addEventListener('click', () => {
          this.$root.$emit('bv::show::modal', 'promote-label-modal');
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

document.addEventListener('DOMContentLoaded', initLabelIndex);
