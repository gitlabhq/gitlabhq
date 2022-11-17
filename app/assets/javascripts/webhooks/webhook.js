import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import pushEvents from './components/push_events.vue';

export function initPushEventsEditForm() {
  const el = document.querySelector('.js-vue-push-events');

  if (!el) return false;

  const provide = {
    isNewHook: parseBoolean(el.dataset.isNewHook),
    pushEvents: parseBoolean(el.dataset.pushEvents),
    strategy: el.dataset.strategy,
    pushEventsBranchFilter: el.dataset.pushEventsBranchFilter,
  };
  return new Vue({
    el,
    provide,
    render(createElement) {
      return createElement(pushEvents);
    },
  });
}
