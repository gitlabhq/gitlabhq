import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import App from './components/app.vue';

export const initOrganizationsShow = () => {
  const el = document.getElementById('js-organizations-show');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { organization, canAdminOrganization } = convertObjectPropsToCamelCase(JSON.parse(appData));

  return initVueApp({
    el,
    name: 'OrganizationShowRoot',
    component: App,
    props: {
      organization,
      canAdminOrganization,
    },
  });
};
