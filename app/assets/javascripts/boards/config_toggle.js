import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ConfigToggle from './components/config_toggle.vue';

export default () => {
  const el = document.querySelector('.js-board-config');

  if (!el) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'ConfigToggleRoot',
    render(h) {
      return h(ConfigToggle, {
        props: {
          canAdminList: parseBoolean(el.dataset.canAdminList),
          hasScope: parseBoolean(el.dataset.hasScope),
        },
      });
    },
  });
};
