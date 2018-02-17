import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import initLabels from '~/init_labels';
import eventHub from '../event_hub';
import PromoteLabelModal from '../components/promote_label_modal.vue';

Vue.use(Translate);

const onRequestFinished = ({ labelUrl, successful }) => {
  const button = document.querySelector(`.js-promote-project-label[data-url="${labelUrl}"]`);

  if (!successful) {
    button.removeAttribute('disabled');
  }
};

const onRequestStarted = (labelUrl) => {
  const button = document.querySelector(`.js-promote-project-label[data-url="${labelUrl}"]`);
  button.setAttribute('disabled', '');
  eventHub.$once('promoteLabelModal.requestFinished', onRequestFinished);
};

const onDeleteButtonClick = (event) => {
  const button = event.currentTarget;
  const modalProps = {
    labelTitle: button.dataset.labelTitle,
    labelColor: button.dataset.labelColor,
    url: button.dataset.url,
  };
  eventHub.$once('promoteLabelModal.requestStarted', onRequestStarted);
  eventHub.$emit('promoteLabelModal.props', modalProps);
};

const promoteLabelButtons = document.querySelectorAll('.js-promote-project-label');
promoteLabelButtons.forEach((button) => {
  button.addEventListener('click', onDeleteButtonClick);
});

eventHub.$once('promoteLabelModal.mounted', () => {
  promoteLabelButtons.forEach((button) => {
    button.removeAttribute('disabled');
  });
});

const initLabelIndex = () => {
  initLabels();

  const promoteLabelModalComponent = new Vue({
    el: '#promote-label-modal',
    components: {
      PromoteLabelModal,
    },
    data() {
      return {
        modalProps: {
          labelTitle: '',
          labelColor: '',
          url: '',
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

  const promoteLabelModal = document.getElementById('promote-label-modal');
  let withLabel;
  if (promoteLabelModal != null) {
    withLabel = promoteLabelModalComponent;
  }
  return withLabel;
};

document.addEventListener('DOMContentLoaded', initLabelIndex);
