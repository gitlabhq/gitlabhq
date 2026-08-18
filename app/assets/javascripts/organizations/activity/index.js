import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OrganizationsActivityApp from './components/app.vue';

export const initOrganizationsActivity = () => {
  const el = document.getElementById('js-organizations-activity');

  const {
    dataset: { appData },
  } = el;
  const { organizationActivityPath, organizationActivityEventTypes, organizationActivityAllEvent } =
    convertObjectPropsToCamelCase(JSON.parse(appData));

  return initVueApp({
    el,
    name: 'OrganizationsActivityRoot',
    component: OrganizationsActivityApp,
    props: {
      organizationActivityPath,
      organizationActivityEventTypes,
      organizationActivityAllEvent,
    },
  });
};
