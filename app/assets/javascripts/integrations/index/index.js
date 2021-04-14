import Vue from 'vue';
import IntegrationList from './components/integrations_list.vue';

export default () => {
  const el = document.querySelector('.js-integrations-list');

  if (!el) {
    return null;
  }

  const { integrations } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(IntegrationList, {
        props: {
          integrations: JSON.parse(integrations),
        },
      });
    },
  });
};
