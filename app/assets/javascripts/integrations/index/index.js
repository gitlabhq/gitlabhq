import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import IntegrationList from './components/integrations_list.vue';

export default () => {
  const el = document.querySelector('.js-integrations-list');

  if (!el) {
    return null;
  }

  const { integrations, isAdmin } = el.dataset;

  return new Vue({
    el,
    name: 'IntegrationListRoot',
    provide() {
      return {
        isAdmin: parseBoolean(isAdmin),
      };
    },
    render(createElement) {
      return createElement(IntegrationList, {
        props: {
          integrations: JSON.parse(integrations),
        },
      });
    },
  });
};
