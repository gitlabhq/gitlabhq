import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import initLabels from '~/init_labels';
import eventHub from '../event_hub';
import PromoteLabelModal from '../components/promote_label_modal.vue';

Vue.use(Translate);

const initLabelIndex = () => {
  initLabels();

  const onRequestFinished = ({ labelUrl, successful }) => {
    const button = document.querySelector(`.js-promote-project-label-button[data-url="${labelUrl}"]`);

    if (!successful) {
      button.removeAttribute('disabled');
    }
  };

  const onRequestStarted = (labelUrl) => {
    const button = document.querySelector(`.js-promote-project-label-button[data-url="${labelUrl}"]`);
    button.setAttribute('disabled', '');
    eventHub.$once('promoteLabelModal.requestFinished', onRequestFinished);
  };

  const onDeleteButtonClick = (event) => {
    const button = event.currentTarget;
    const modalProps = {
      labelTitle: button.dataset.labelTitle,
      labelColor: button.dataset.labelColor,
      labelTextColor: button.dataset.labelTextColor,
      url: button.dataset.url,
      groupName: button.dataset.groupName,
    };
    eventHub.$once('promoteLabelModal.requestStarted', onRequestStarted);
    eventHub.$emit('promoteLabelModal.props', modalProps);
  };

  const promoteLabelButtons = document.querySelectorAll('.js-promote-project-label-button');
  promoteLabelButtons.forEach((button) => {
    button.addEventListener('click', onDeleteButtonClick);
  });

  eventHub.$once('promoteLabelModal.mounted', () => {
    promoteLabelButtons.forEach((button) => {
      button.removeAttribute('disabled');
    });
  });

  const promoteLabelModal = document.getElementById('promote-label-modal');
  let promoteLabelModalComponent;

  if (promoteLabelModal) {
    promoteLabelModalComponent = new Vue({
      el: promoteLabelModal,
      components: {
        PromoteLabelModal,
      },
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
        return createElement('promote-label-modal', {
          props: this.modalProps,
        });
      },
    });
  }

  return promoteLabelModalComponent;
};

document.addEventListener('DOMContentLoaded', initLabelIndex);
