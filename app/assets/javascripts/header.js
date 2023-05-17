import Vue from 'vue';
import NewNavToggle from '~/nav/components/new_nav_toggle.vue';
import { highCountTrim } from '~/lib/utils/text_utility';
import Tracking from '~/tracking';
import Translate from '~/vue_shared/translate';
import { parseBoolean } from '~/lib/utils/common_utils';

/**
 * Updates todo counter when todos are toggled.
 * When count is 0, we hide the badge.
 *
 * @param {jQuery.Event} e
 * @param {String} count
 */
export default function initTodoToggle() {
  document.addEventListener('todo:toggle', (e) => {
    const updatedCount = e.detail.count || 0;
    const todoPendingCount = document.querySelector('.js-todos-count');

    if (todoPendingCount) {
      todoPendingCount.textContent = highCountTrim(updatedCount);
      if (updatedCount === 0) {
        todoPendingCount.classList.add('hidden');
      } else {
        todoPendingCount.classList.remove('hidden');
      }
    }
  });
}

export function initStatusTriggers() {
  const setStatusModalTriggerEl = document.querySelector('.js-set-status-modal-trigger');

  if (setStatusModalTriggerEl) {
    setStatusModalTriggerEl.addEventListener('click', () => {
      const topNavbar = document.querySelector('.navbar-gitlab');
      const buttonWithinTopNav = topNavbar && topNavbar.contains(setStatusModalTriggerEl);
      Tracking.event(undefined, 'click_button', {
        label: 'user_edit_status',
        property: buttonWithinTopNav ? 'navigation_top' : 'nav_user_menu',
      });

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

    setStatusModalTriggerEl.classList.add('ready');
  }
}

function trackShowUserDropdownLink(trackEvent, elToTrack, el) {
  const { trackLabel, trackProperty } = elToTrack.dataset;

  el.addEventListener('shown.bs.dropdown', () => {
    Tracking.event(document.body.dataset.page, trackEvent, {
      label: trackLabel,
      property: trackProperty,
    });
  });
}

export function initNavUserDropdownTracking() {
  const el = document.querySelector('.js-nav-user-dropdown');
  const buyEl = document.querySelector('.js-buy-pipeline-minutes-link');

  if (el && buyEl) {
    trackShowUserDropdownLink('show_buy_ci_minutes', buyEl, el);
  }
}

function initNewNavToggle() {
  const el = document.querySelector('.js-new-nav-toggle');
  if (!el) return false;

  return new Vue({
    el,
    render(h) {
      return h(NewNavToggle, {
        props: {
          enabled: parseBoolean(el.dataset.enabled),
          endpoint: el.dataset.endpoint,
        },
      });
    },
  });
}

if (!gon?.use_new_navigation) {
  requestIdleCallback(initStatusTriggers);
}
requestIdleCallback(initNavUserDropdownTracking);
requestIdleCallback(initNewNavToggle);
