import $ from 'jquery';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { highCountTrim } from '~/lib/utils/text_utility';
import setStatusModalTrigger from './set_status_modal/set_status_modal_trigger.vue';
// import setStatusModalWrapper from './set_status_modal/set_status_modal_wrapper.vue';

/**
 * Updates todo counter when todos are toggled.
 * When count is 0, we hide the badge.
 *
 * @param {jQuery.Event} e
 * @param {String} count
 */
export default function initTodoToggle() {
  $(document).on('todo:toggle', (e, count) => {
    const parsedCount = parseInt(count, 10);
    const $todoPendingCount = $('.todos-count');

    $todoPendingCount.text(highCountTrim(parsedCount));
    $todoPendingCount.toggleClass('hidden', parsedCount === 0);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const setStatusModalTriggerEl = document.querySelector('.js-set-status-modal-trigger');
  // const setStatusModalWrapperEl = document.querySelector('.js-set-status-modal-wrapper');

  if (setStatusModalTriggerEl || setStatusModalWrapperEl) {
    Vue.use(Translate);

    new Vue({
      el: setStatusModalTriggerEl,
      render(createElement) {
        return createElement(setStatusModalTrigger);
      },
    });

    // new Vue({
    //   el: setStatusModalWrapperEl,
    //   render(createElement) {
    //     return createElement(setStatusModalWrapper);
    //   },
    // });
  }
});
