import $ from 'jquery';
import Vue from 'vue';
import { highCountTrim } from '~/lib/utils/text_utility';
import Tracking from '~/tracking';
import Translate from '~/vue_shared/translate';

/**
 * Updates todo counter when todos are toggled.
 * When count is 0, we hide the badge.
 *
 * @param {jQuery.Event} e
 * @param {String} count
 */
export default function initTodoToggle() {
  $(document).on('todo:toggle', (e, count) => {
    const updatedCount = count || e?.detail?.count || 0;
    const $todoPendingCount = $('.js-todos-count');

    $todoPendingCount.text(highCountTrim(updatedCount));
    $todoPendingCount.toggleClass('hidden', updatedCount === 0);
  });
}

function initStatusTriggers() {
  const setStatusModalTriggerEl = document.querySelector('.js-set-status-modal-trigger');

  if (setStatusModalTriggerEl) {
    setStatusModalTriggerEl.addEventListener('click', () => {
      import(
        /* webpackChunkName: 'statusModalBundle' */ './set_status_modal/set_status_modal_wrapper.vue'
      )
        .then(({ default: SetStatusModalWrapper }) => {
          const setStatusModalWrapperEl = document.querySelector('.js-set-status-modal-wrapper');
          const statusModalElement = document.createElement('div');
          setStatusModalWrapperEl.appendChild(statusModalElement);

          Vue.use(Translate);

          // eslint-disable-next-line no-new
          new Vue({
            el: statusModalElement,
            data() {
              const {
                currentEmoji,
                defaultEmoji,
                currentMessage,
                currentAvailability,
                currentClearStatusAfter,
              } = setStatusModalWrapperEl.dataset;

              return {
                currentEmoji,
                defaultEmoji,
                currentMessage,
                currentAvailability,
                currentClearStatusAfter,
              };
            },
            render(createElement) {
              const {
                currentEmoji,
                defaultEmoji,
                currentMessage,
                currentAvailability,
                currentClearStatusAfter,
              } = this;

              return createElement(SetStatusModalWrapper, {
                props: {
                  currentEmoji,
                  defaultEmoji,
                  currentMessage,
                  currentAvailability,
                  currentClearStatusAfter,
                },
              });
            },
          });
        })
        .catch(() => {});
    });
  }
}

function trackShowUserDropdownLink(trackEvent, elToTrack, el) {
  const { trackLabel, trackProperty } = elToTrack.dataset;

  $(el).on('shown.bs.dropdown', () => {
    Tracking.event(document.body.dataset.page, trackEvent, {
      label: trackLabel,
      property: trackProperty,
    });
  });
}
export function initNavUserDropdownTracking() {
  const el = document.querySelector('.js-nav-user-dropdown');
  const buyEl = document.querySelector('.js-buy-pipeline-minutes-link');
  const upgradeEl = document.querySelector('.js-upgrade-plan-link');

  if (el && buyEl) {
    trackShowUserDropdownLink('show_buy_ci_minutes', buyEl, el);
  }

  if (el && upgradeEl) {
    trackShowUserDropdownLink('show_upgrade_link', upgradeEl, el);
  }
}

requestIdleCallback(initStatusTriggers);
requestIdleCallback(initNavUserDropdownTracking);
