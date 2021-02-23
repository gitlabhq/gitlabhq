import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ConfigToggle from './components/config_toggle.vue';

export default (boardsStore) => {
  const el = document.querySelector('.js-board-config');

  if (!el) {
    return;
  }

  gl.boardConfigToggle = new Vue({
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
