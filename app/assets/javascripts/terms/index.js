import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import TermsApp from 'jh_else_ce/terms/components/app.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const initTermsApp = () => {
  const el = document.getElementById('js-terms-of-service');

  if (!el) return false;

  const { terms, permissions, paths } = convertObjectPropsToCamelCase(
    JSON.parse(el.dataset.termsData),
    { deep: true },
  );

  return initVueApp({
    el,
    name: 'TermsAppRoot',
    provide: { terms, permissions, paths },
    component: TermsApp,
  });
};
