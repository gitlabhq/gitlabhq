import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OrganizationsActivityApp from './components/app.vue';

export const initOrganizationsActivity = () => {
  const el = document.getElementById('js-organizations-activity');

  const {
    dataset: { appData },
  } = el;
  const { organizationActivityPath, organizationActivityEventTypes, organizationActivityAllEvent } =
    convertObjectPropsToCamelCase(JSON.parse(appData));

  return new Vue({
    el,
    name: 'OrganizationsActivityRoot',
    render(createElement) {
      return createElement(OrganizationsActivityApp, {
        props: {
          organizationActivityPath,
          organizationActivityEventTypes,
          organizationActivityAllEvent,
        },
      });
    },
  });
};
