import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import CompareApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-compare-selector');
  if (!el) return null;

  const {
    sourceProjectRefsPath,
    targetProjectRefsPath,
    paramsFrom,
    paramsTo,
    straight,
    projectCompareIndexPath,
    projectMergeRequestPath,
    createMrPath,
    sourceProject,
    targetProject,
    targetProjectsPath,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'CompareAppRoot',
    provide: {
      targetProjectsPath,
    },
    component: CompareApp,
    props: {
      sourceProjectRefsPath,
      targetProjectRefsPath,
      paramsFrom,
      paramsTo,
      straight: parseBoolean(straight),
      projectCompareIndexPath,
      projectMergeRequestPath,
      createMrPath,
      sourceProject: JSON.parse(sourceProject),
      targetProject: JSON.parse(targetProject),
    },
  });
}
