import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ConfigToggle from './components/config_toggle.vue';

export default (boardsStore = undefined) => {
  const el = document.querySelector('.js-board-config');

  if (!el) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(h) {
      return h(ConfigToggle, {
        props: {
          boardsStore,
          canAdminList: parseBoolean(el.dataset.canAdminList),
          hasScope: parseBoolean(el.dataset.hasScope),
        },
      });
    },
  });
};
