import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AbuseReportsApp from './components/app.vue';

export const initAbuseReportsApp = () => {
  const el = document.querySelector('#js-abuse-reports-list-app');

  if (!el) {
    return null;
  }

  const { abuseReportsData } = el.dataset;
  const { categories, reports, pagination } = convertObjectPropsToCamelCase(
    JSON.parse(abuseReportsData),
    {
      deep: true,
    },
  );

  return initVueApp({
    el,
    name: 'AbuseReportsAppRoot',
    provide: { categories },
    component: AbuseReportsApp,
    props: {
      abuseReports: reports,
      pagination,
    },
  });
};
