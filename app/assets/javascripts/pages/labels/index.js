import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import deleteLabelModal from './components/delete_label_modal.vue';
import eventHub from './event_hub';

export default () => {
  Vue.use(Translate);

  const onRequestFinished = ({ labelUrl, successful }) => {
    const button = document.querySelector(`.js-delete-project-label[data-url="${labelUrl}"]`);

    if (!successful) {
      button.removeAttribute('disabled');
    }
  };

  const onRequestStarted = (labelUrl) => {
    const button = document.querySelector(`.js-delete-project-label[data-url="${labelUrl}"]`);
    button.setAttribute('disabled', '');
    eventHub.$once('deleteLabelModal.requestFinished', onRequestFinished);
  };

  const onDeleteButtonClick = (event) => {
    const button = event.currentTarget;
    const modalProps = {
      labelTitle: button.dataset.labelTitle,
      openMergeRequestCount: parseInt(button.dataset.labelOpenMergeRequestsCount, 10),
      openIssuesCount: parseInt(button.dataset.labelOpenIssuesCount, 10),
      url: button.dataset.url,
    };
    eventHub.$once('deleteLabelModal.requestStarted', onRequestStarted);
    eventHub.$emit('deleteLabelModal.props', modalProps);
  };

  const deleteLabelButtons = document.querySelectorAll('.js-delete-project-label');
  for (let i = 0; i < deleteLabelButtons.length; i += 1) {
    const button = deleteLabelButtons[i];
    button.addEventListener('click', onDeleteButtonClick);
  }

  eventHub.$once('deleteLabelModal.mounted', () => {
    for (let i = 0; i < deleteLabelButtons.length; i += 1) {
      const button = deleteLabelButtons[i];
      button.removeAttribute('disabled');
    }
  });

  const labelComponent = new Vue({
    el: '#delete-label-modal',
    components: {
      deleteLabelModal,
    },
    data() {
      return {
        modalProps: {
          labelTitle: '',
          openMergeRequestCount: -1,
          openIssuesCount: -1,
          url: '',
        },
      };
    },
    mounted() {
      eventHub.$on('deleteLabelModal.props', this.setModalProps);
      eventHub.$emit('deleteLabelModal.mounted');
    },
    beforeDestroy() {
      eventHub.$off('deleteLabelModal.props', this.setModalProps);
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement('delete-label-modal', {
        props: this.modalProps,
      });
    },
  });

  const labelModal = document.getElementById('delete-label-modal');
  let withLabel;
  if (labelModal != null) {
    withLabel = labelComponent;
  }
  return withLabel;
};
