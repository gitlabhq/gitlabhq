import Vue from 'vue';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import App from './components/app.vue';

export const initOrganizationsGroupsEdit = () => {
  const el = document.getElementById('js-organizations-groups-edit');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { group } = convertObjectPropsToCamelCase(JSON.parse(appData), { deep: true });

  return new Vue({
    el,
    name: 'OrganizationGroupsEditRoot',
    provide: {
      group,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
