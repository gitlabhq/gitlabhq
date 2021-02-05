import Vue from 'vue';
import CompareApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-compare-selector');
  const {
    refsProjectPath,
    paramsFrom,
    paramsTo,
    projectCompareIndexPath,
    projectMergeRequestPath,
    createMrPath,
  } = el.dataset;

  return new Vue({
    el,
    components: {
      CompareApp,
    },
    render(createElement) {
      return createElement(CompareApp, {
        props: {
          refsProjectPath,
          paramsFrom,
          paramsTo,
          projectCompareIndexPath,
          projectMergeRequestPath,
          createMrPath,
        },
      });
    },
  });
}
