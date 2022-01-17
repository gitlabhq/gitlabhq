import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';
import { inferLicensePlan } from './hierarchy_util';

export const initWorkItemsHierarchy = () => {
  const el = document.querySelector('#js-work-items-hierarchy');

  const { illustrationPath, hasEpics, hasSubEpics } = el.dataset;

  const licensePlan = inferLicensePlan({
    hasEpics: parseBoolean(hasEpics),
    hasSubEpics: parseBoolean(hasSubEpics),
  });

  return new Vue({
    el,
    provide: {
      illustrationPath,
      licensePlan,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
