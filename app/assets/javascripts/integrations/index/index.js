import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import IntegrationList from './components/integrations_list.vue';

export default () => {
  const el = document.querySelector('.js-integrations-list');

  if (!el) {
    return null;
  }

  const { integrations } = el.dataset;

  return initVueApp({
    el,
    name: 'IntegrationListRoot',
    component: IntegrationList,
    props: {
      integrations: JSON.parse(integrations),
    },
  });
};
