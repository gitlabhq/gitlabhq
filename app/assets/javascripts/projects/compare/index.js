import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import CompareApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-compare-selector');

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
    projectsFrom,
  } = el.dataset;

  return new Vue({
    el,
    components: {
      CompareApp,
    },
    render(createElement) {
      return createElement(CompareApp, {
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
          projects: JSON.parse(projectsFrom),
        },
      });
    },
  });
}
