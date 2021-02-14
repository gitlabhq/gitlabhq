import { GlToast } from '@gitlab/ui';
import Vue from 'vue';

import { parseBoolean } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import SettingsApp from './components/group_settings_app.vue';
import { apolloProvider } from './graphql';

Vue.use(Translate);
Vue.use(GlToast);

export default () => {
  const el = document.getElementById('js-packages-and-registries-settings');
  if (!el) {
    return null;
  }
  return new Vue({
    el,
    apolloProvider,
    provide: {
      defaultExpanded: parseBoolean(el.dataset.defaultExpanded),
      groupPath: el.dataset.groupPath,
    },
    render(createElement) {
      return createElement(SettingsApp);
    },
  });
};
