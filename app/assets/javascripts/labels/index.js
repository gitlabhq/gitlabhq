import $ from 'jquery';
import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Translate from '~/vue_shared/translate';
import DeleteLabelModal from './components/delete_label_modal.vue';
import LabelActions from './components/label_actions.vue';
import PromoteLabelModal from './components/promote_label_modal.vue';
import eventHub, {
  EVENT_DELETE_LABEL_MODAL_SUCCESS,
  EVENT_OPEN_DELETE_LABEL_MODAL,
  EVENT_OPEN_PROMOTE_LABEL_MODAL,
} from './event_hub';
import GroupLabelSubscription from './group_label_subscription';
import LabelManager from './label_manager';
import ProjectLabelSubscription from './project_label_subscription';

export function initDeleteLabelModal(optionalProps = {}) {
  document.querySelectorAll('.js-delete-label-modal-button').forEach((button) => {
    button.addEventListener('click', (e) => {
      e.preventDefault();
      eventHub.$emit(EVENT_OPEN_DELETE_LABEL_MODAL, button.dataset);
    });
  });

  new Vue({
    name: 'DeleteLabelModalRoot',
    render(h) {
      return h(DeleteLabelModal, {
        props: {
          ...optionalProps,
        },
      });
    },
  }).$mount();
}

export function initLabelActions(el) {
  const {
    labelId,
    labelName,
    labelColor,
    labelTextColor,
    subjectName,
    groupName,
    editPath,
    promotePath,
    destroyPath,
  } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(LabelActions, {
        props: {
          labelId,
          labelName,
          labelColor,
          labelTextColor,
          subjectName,
          groupName,
          editPath,
          promotePath,
          destroyPath,
        },
      });
    },
  });
}

export function initLabelsActions() {
  document.querySelectorAll('.js-vue-label-actions').forEach(initLabelActions);
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
  initLabelsActions();
}

export function initLabelIndex() {
  Vue.use(Translate);

  initLabels();
  initDeleteLabelModal();

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
      eventHub.$on(EVENT_OPEN_PROMOTE_LABEL_MODAL, this.openModal);
      eventHub.$emit('promoteLabelModal.mounted');
    },
    beforeDestroy() {
      eventHub.$off(EVENT_OPEN_PROMOTE_LABEL_MODAL, this.openModal);
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
      openModal(modalProps) {
        this.setModalProps(modalProps);
        this.$root.$emit(BV_SHOW_MODAL, 'promote-label-modal');
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

  function removeLabelSuccessCallback(labelId) {
    document.getElementById(`label_${labelId}`).classList.add('!gl-hidden');

    const labelsCount = document.querySelectorAll(
      'ul.manage-labels-list .js-label-list-item:not(.\\!gl-hidden)',
    ).length;

    // update labels count in UI
    document.querySelector('.js-admin-labels-count').innerText = labelsCount;

    // display the empty state if there are no more labels
    if (labelsCount < 1 && !pagination && emptyState) {
      emptyState.classList.remove('gl-hidden');
      labelsContainer.classList.add('gl-hidden');
    }
  }

  initDeleteLabelModal({ remoteDestroy: true });
  eventHub.$on(EVENT_DELETE_LABEL_MODAL_SUCCESS, removeLabelSuccessCallback);
  initLabelsActions();
}
