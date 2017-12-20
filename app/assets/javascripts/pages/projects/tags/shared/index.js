
import Vue from 'vue';

import Translate from '~/vue_shared/translate';

import deleteTagModal from './components/delete_tag_modal.vue';
import eventHub from './event_hub';

export default () => {
  Vue.use(Translate);

  const onRequestFinished = ({ url, successful }) => {
    const button = document.querySelector(`.js-delete-tag-button[data-url="${url}"]`);

    if (!successful) {
      button.removeAttribute('disabled');
    }

    button.querySelector('.js-loading-icon').classList.add('hidden');
  };

  const onRequestStarted = (url) => {
    const button = document.querySelector(`.js-delete-tag-button[data-url="${url}"]`);
    button.setAttribute('disabled', '');
    button.querySelector('.js-loading-icon').classList.remove('hidden');
    eventHub.$once('deleteTagModal.requestFinished', onRequestFinished);
  };

  const onDeleteButtonClick = (event) => {
    const button = event.currentTarget;
    const modalProps = {
      tagName: button.dataset.tagName,
      url: button.dataset.url,
      redirectUrl: button.dataset.redirectUrl,
    };
    eventHub.$once('deleteTagModal.requestStarted', onRequestStarted);
    eventHub.$emit('deleteTagModal.props', modalProps);
  };

  const deleteTagButtons = document.querySelectorAll('.js-delete-tag-button:not([data-protected])');
  deleteTagButtons.forEach((button) => {
    button.addEventListener('click', onDeleteButtonClick);
  });

  eventHub.$once('deleteTagModal.mounted', () => {
    deleteTagButtons.forEach((button) => {
      button.removeAttribute('disabled');
    });
  });

  return new Vue({
    el: '#delete-tag-modal',
    components: {
      deleteTagModal,
    },
    data() {
      return {
        tagName: '',
        url: '',
        redirectUrl: '',
      };
    },
    mounted() {
      eventHub.$on('deleteTagModal.props', this.setModalProps);
      eventHub.$emit('deleteTagModal.mounted');
    },
    beforeDestroy() {
      eventHub.$off('deleteTagModal.props', this.setModalProps);
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement(deleteTagModal, {
        props: this.modalProps,
      });
    },
  });
};
