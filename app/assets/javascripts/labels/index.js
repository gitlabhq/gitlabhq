import $ from 'jquery';
import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import DeleteLabelModal from './components/delete_label_modal.vue';
import PromoteLabelModal from './components/promote_label_modal.vue';
import eventHub from './event_hub';
import GroupLabelSubscription from './group_label_subscription';
import LabelManager from './label_manager';
import ProjectLabelSubscription from './project_label_subscription';

export function initDeleteLabelModal(optionalProps = {}) {
  new Vue({
    name: 'DeleteLabelModalRoot',
    render(h) {
      return h(DeleteLabelModal, {
        props: {
          selector: '.js-delete-label-modal-button',
          ...optionalProps,
        },
      });
    },
  }).$mount();
}

export function initLabels() {
  if ($('.prioritized-labels').length) {
    new LabelManager(); // eslint-disable-line no-new
  }
  $('.js-label-subscription').each((i, el) => {
    const $el = $(el);

    if ($el.find('.dropdown-group-label').length) {
      new GroupLabelSubscription($el); // eslint-disable-line no-new
    } else {
      new ProjectLabelSubscription($el); // eslint-disable-line no-new
    }
  });
}

export function initLabelIndex() {
  Vue.use(Translate);

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
    name: 'PromoteLabelModal',
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
}

export function initAdminLabels() {
  const labelsContainer = document.querySelector('.js-admin-labels-container');
  const pagination = labelsContainer?.querySelector('.gl-pagination');
  const emptyState = document.querySelector('.js-admin-labels-empty-state');

  function removeLabelSuccessCallback() {
    this.closest('li.label-list-item').classList.add('gl-display-none!');

    const labelsCount = document.querySelectorAll(
      'ul.manage-labels-list li.label-list-item:not(.gl-display-none\\!)',
    ).length;

    // display the empty state if there are no more labels
    if (labelsCount < 1 && !pagination && emptyState) {
      emptyState.classList.remove('gl-display-none');
    }
  }

  document.querySelectorAll('.js-remove-label').forEach((row) => {
    row.addEventListener('ajax:success', removeLabelSuccessCallback);
  });
}
