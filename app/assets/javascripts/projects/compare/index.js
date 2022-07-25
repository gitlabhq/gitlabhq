import Vue from 'vue';
import CompareApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-compare-selector');

  const {
    sourceProjectRefsPath,
    targetProjectRefsPath,
    paramsFrom,
    paramsTo,
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
