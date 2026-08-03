import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import IntegrationList from './components/integrations_list.vue';

export default () => {
  const el = document.querySelector('.js-integrations-list');

  if (!el) {
    return null;
  }

  const { integrations, isAdmin } = el.dataset;

  return initVueApp({
    el,
    name: 'IntegrationListRoot',
    provide() {
      return {
        isAdmin: parseBoolean(isAdmin),
      };
    },
    component: IntegrationList,
    props: {
      integrations: JSON.parse(integrations),
    },
  });
};
