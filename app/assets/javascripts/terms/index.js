import Vue from 'vue';

import TermsApp from 'jh_else_ce/terms/components/app.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const initTermsApp = () => {
  const el = document.getElementById('js-terms-of-service');

  if (!el) return false;

  const { terms, permissions, paths } = convertObjectPropsToCamelCase(
    JSON.parse(el.dataset.termsData),
    { deep: true },
  );

  return new Vue({
    el,
    provide: { terms, permissions, paths },
    render(createElement) {
      return createElement(TermsApp);
    },
  });
};
