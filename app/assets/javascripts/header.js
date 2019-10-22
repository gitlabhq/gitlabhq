import $ from 'jquery';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { highCountTrim } from '~/lib/utils/text_utility';
import SetStatusModalTrigger from './set_status_modal/set_status_modal_trigger.vue';
import SetStatusModalWrapper from './set_status_modal/set_status_modal_wrapper.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

/**
 * Updates todo counter when todos are toggled.
 * When count is 0, we hide the badge.
 *
 * @param {jQuery.Event} e
 * @param {String} count
 */
export default function initTodoToggle() {
  $(document).on('todo:toggle', (e, count) => {
    const $todoPendingCount = $('.todos-count');

    $todoPendingCount.text(highCountTrim(count));
    $todoPendingCount.toggleClass('hidden', count === 0);
  });
}

function initStatusTriggers() {
  const setStatusModalTriggerEl = document.querySelector('.js-set-status-modal-trigger');
  const setStatusModalWrapperEl = document.querySelector('.js-set-status-modal-wrapper');

  if (setStatusModalTriggerEl || setStatusModalWrapperEl) {
    Vue.use(Translate);

    // eslint-disable-next-line no-new
    new Vue({
      el: setStatusModalTriggerEl,
      data() {
        const { hasStatus } = this.$options.el.dataset;

        return {
          hasStatus: parseBoolean(hasStatus),
        };
      },
      render(createElement) {
        return createElement(SetStatusModalTrigger, {
          props: {
            hasStatus: this.hasStatus,
          },
        });
      },
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: setStatusModalWrapperEl,
      data() {
        const { currentEmoji, currentMessage } = this.$options.el.dataset;

        return {
          currentEmoji,
          currentMessage,
        };
      },
      render(createElement) {
        const { currentEmoji, currentMessage } = this;

        return createElement(SetStatusModalWrapper, {
          props: {
            currentEmoji,
            currentMessage,
          },
        });
      },
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  requestIdleCallback(initStatusTriggers);
});
