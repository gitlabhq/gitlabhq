import Vue from 'vue';
import Popover from './components/popover.vue';

export default (el) =>
  new Vue({
    el,
    render(createElement) {
      return createElement(Popover, {
        props: {
          target: el.dataset.target,
          trackLabel: el.dataset.trackLabel,
          dismissKey: el.dataset.dismissKey,
          mergeRequestPath: el.dataset.mergeRequestPath,
          humanAccess: el.dataset.humanAccess,
        },
      });
    },
  });
